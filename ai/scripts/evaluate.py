#!/usr/bin/env python3
"""
Train a text moderation classifier with Hugging Face Transformers
and export to Core ML (.mlmodel).

Expected data files: train.jsonl, valid.jsonl (and optional test.jsonl),
with each line like:
{"text": "...", "label": "safe"}  # label may be int or string

Usage (basic):
  python train.py \
    --model distilbert-base-uncased \
    --train train.jsonl --valid valid.jsonl \
    --out_dir outputs/moderation-distilbert \
    --epochs 2 --batch_size 16 --max_length 256 \
    --export_coreml

Notes:
- This script will auto-infer the label set from your data
  and save id2label/label2id in out_dir.
- Core ML export produces: model.mlmodel inside out_dir/coreml/
"""

import argparse, json, os, numpy as np, torch
from sklearn.metrics import f1_score, precision_recall_fscore_support
from transformers import AutoTokenizer, AutoModelForSequenceClassification

def load_jsonl(path):
    return [json.loads(l) for l in open(path,'r',encoding='utf-8') if l.strip()]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--model', required=True)
    ap.add_argument('--test', required=True)
    ap.add_argument('--labels', nargs='+', required=True)
    ap.add_argument('--threshold', type=float, default=0.5)
    ap.add_argument('--max-length', type=int, default=128)
    args = ap.parse_args()

    tok = AutoTokenizer.from_pretrained(args.model, use_fast=True)
    mdl = AutoModelForSequenceClassification.from_pretrained(args.model).eval()

    rows = load_jsonl(args.test)
    texts = [r['text'] for r in rows]
    y_true = np.array([[int(r['labels'].get(k,0)) for k in args.labels] for r in rows])

    probs = []
    bs = 16
    for i in range(0, len(texts), bs):
        batch = texts[i:i+bs]
        enc = tok(batch, truncation=True, max_length=args.max_length, padding=True, return_tensors='pt')
        with torch.no_grad():
            logits = mdl(**enc).logits.numpy()
        p = 1/(1+np.exp(-logits))
        probs.append(p)
    probs = np.vstack(probs)

    y_pred = (probs >= args.threshold).astype(int)
    print("F1 micro:", f1_score(y_true, y_pred, average='micro', zero_division=0))
    print("F1 macro:", f1_score(y_true, y_pred, average='macro', zero_division=0))
    for idx, name in enumerate(args.labels):
        p, r, f, _ = precision_recall_fscore_support(y_true[:,idx], y_pred[:,idx], average='binary', zero_division=0)
        print(f"{name:15s} P={p:.3f} R={r:.3f} F1={f:.3f}")

    # dumps para busca de thresholds
    np.savez(os.path.join(args.model,'preds_test.npz'), probs=probs)
    np.savez(os.path.join(args.model,'y_test.npz'), y=y_true)
    print("Saved dumps to", args.model)

if __name__ == '__main__':
    main()
