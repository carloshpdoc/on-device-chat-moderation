import argparse, json, os, torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import onnx

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--model', required=True, help='dir do modelo treinado (pytorch_model.bin + config.json)')
    ap.add_argument('--labels', nargs='+', default=["toxicity","insult","hate","sexual","threat","self_harm"])
    ap.add_argument('--max-length', type=int, default=128)
    ap.add_argument('--out', required=True, help='pasta de saída (será criada se não existir)')
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)

    tok = AutoTokenizer.from_pretrained(args.model, use_fast=True)
    mdl = AutoModelForSequenceClassification.from_pretrained(args.model).eval()

    enc = tok("exemplo", return_tensors='pt', truncation=True, max_length=args.max_length)

    onnx_path = os.path.join(args.out, "model.onnx")
    torch.onnx.export(
        mdl,
        (enc['input_ids'], enc['attention_mask']),
        onnx_path,
        input_names=["input_ids", "attention_mask"],
        output_names=["logits"],
        dynamic_axes={
            "input_ids": {0: "batch", 1: "seq"},
            "attention_mask": {0: "batch", 1: "seq"},
            "logits": {0: "batch"}
        },
        opset_version=17
    )

    # Validação simples
    onnx_model = onnx.load(onnx_path)
    onnx.checker.check_model(onnx_model)
    print("ONNX exportado e validado em:", onnx_path)

    # Salva tokenizer e labels para o app Android
    tok.save_pretrained(args.out)  # vocab.txt / tokenizer.json
    with open(os.path.join(args.out, "labels.json"), "w", encoding="utf-8") as f:
        json.dump(args.labels, f, ensure_ascii=False, indent=2)
    print("labels.json e tokenizer salvos em:", args.out)

if __name__ == '__main__':
    main()