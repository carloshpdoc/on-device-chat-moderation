import argparse, json, os
import datasets as ds
from transformers import (AutoTokenizer, AutoModelForSequenceClassification,
                          DataCollatorWithPadding, Trainer, TrainingArguments)
import torch
from sklearn.metrics import f1_score

def load_jsonl(path):
    return [json.loads(l) for l in open(path,'r',encoding='utf-8') if l.strip()]

def to_hf_dataset(path, label_names):
    rows = load_jsonl(path)
    texts = [r['text'] for r in rows]
    # labels = [[int(r['labels'].get(k,0)) for k in label_names] for r in rows]
    labels = [[float(int(r['labels'].get(k, 0))) for k in label_names] for r in rows]
    return {'text': texts, 'labels': labels}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--model', default='distilbert-base-multilingual-cased')
    ap.add_argument('--train', required=True)
    ap.add_argument('--valid', required=True)
    ap.add_argument('--labels', nargs='+', required=True)
    ap.add_argument('--epochs', type=int, default=3)
    ap.add_argument('--lr', type=float, default=5e-5)
    ap.add_argument('--batch', type=int, default=16)
    ap.add_argument('--max-length', type=int, default=128)
    ap.add_argument('--outdir', required=True)
    args = ap.parse_args()

    os.makedirs(args.outdir, exist_ok=True)
    with open(os.path.join(args.outdir,'labels.json'),'w', encoding='utf-8') as f:
        json.dump(args.labels, f, ensure_ascii=False, indent=2)

    tr = to_hf_dataset(args.train, args.labels)
    va = to_hf_dataset(args.valid, args.labels)

    tokenizer = AutoTokenizer.from_pretrained(args.model, use_fast=True)
    def tok(examples):
        return tokenizer(examples['text'], truncation=True, max_length=args.max_length)
    dtrain = ds.Dataset.from_dict(tr).map(tok, batched=True, remove_columns=['text'])
    dvalid = ds.Dataset.from_dict(va).map(tok, batched=True, remove_columns=['text'])

    # >>> força a coluna 'labels' para float32 (multi-label precisa disso)
    dtrain = dtrain.cast_column('labels', ds.Sequence(ds.Value('float32')))
    dvalid = dvalid.cast_column('labels', ds.Sequence(ds.Value('float32')))
    
    num_labels = len(args.labels)
    model = AutoModelForSequenceClassification.from_pretrained(
        args.model, num_labels=num_labels, problem_type='multi_label_classification'
    )

    data_collator = DataCollatorWithPadding(tokenizer=tokenizer)

    def compute_metrics(eval_pred):
        logits, labels = eval_pred
        probs = torch.from_numpy(logits).sigmoid().numpy()
        y_pred = (probs >= 0.5).astype(int)
        f1 = f1_score(labels, y_pred, average='macro', zero_division=0)
        return {'macro_f1@0.5': f1}

    training_args = TrainingArguments(
        output_dir=args.outdir,
        learning_rate=args.lr,
        per_device_train_batch_size=args.batch,
        per_device_eval_batch_size=args.batch,
        num_train_epochs=args.epochs,
        evaluation_strategy='epoch',
        save_strategy='epoch',
        load_best_model_at_end=True,
        metric_for_best_model='macro_f1@0.5',
        greater_is_better=True,
        report_to=[],
        fp16=torch.cuda.is_available(),
        logging_steps=10
    )

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=dtrain,
        eval_dataset=dvalid,
        tokenizer=tokenizer,
        data_collator=data_collator,
        compute_metrics=compute_metrics
    )
    trainer.train()
    trainer.save_model(args.outdir)
    tokenizer.save_pretrained(args.outdir)
    print("Saved to", args.outdir)

if __name__ == '__main__':
    main()
