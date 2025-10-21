import argparse, json, os, numpy as np, torch, coremltools as ct
from torch import nn
from transformers import AutoTokenizer, AutoModelForSequenceClassification

class LogitsWrapper(nn.Module):
    """Wrapper para retornar somente logits e fazer cast dos ids para long."""
    def __init__(self, model):
        super().__init__()
        self.model = model

    def forward(self, input_ids, attention_mask):
        # Garante dtype correto esperado pelo modelo HF (Long)
        input_ids = input_ids.long()
        attention_mask = attention_mask.long()
        out = self.model(input_ids=input_ids, attention_mask=attention_mask)
        # out é SequenceClassifierOutput (dict-like); retornamos só o tensor
        return out.logits

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--model', required=True, help='dir do modelo treinado (pytorch_model.bin + config.json)')
    ap.add_argument('--labels', nargs='+', default=["toxicity","insult","hate","sexual","threat","self_harm"])
    ap.add_argument('--max-length', type=int, default=128)
    ap.add_argument('--out', required=True, help='pasta de saída (será criada se não existir)')
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)

    tok = AutoTokenizer.from_pretrained(args.model, use_fast=True)
    mdl = AutoModelForSequenceClassification.from_pretrained(args.model)
    mdl.eval()

    # Envolve o modelo para retornar só logits
    wrapped = LogitsWrapper(mdl).eval()

    # Dummy trace batch=1
    enc = tok("exemplo", return_tensors='pt', truncation=True, max_length=args.max_length)
    # Traçar com strict=False (estrutura de container estável)
    scripted = torch.jit.trace(wrapped, (enc['input_ids'], enc['attention_mask']), strict=False)

    # Converte para Core ML (mlprogram). Vamos declarar input como int32
    # e *dentro* do wrapper convertemos para long (acima).
    mlmodel = ct.convert(
        scripted,
        convert_to="mlprogram",
        inputs=[
            ct.TensorType(name="input_ids", shape=enc['input_ids'].shape, dtype=np.int32),
            ct.TensorType(name="attention_mask", shape=enc['attention_mask'].shape, dtype=np.int32),
        ],
    )

    out_pkg = os.path.join(args.out, "ToxicityClassifier.mlpackage")
    mlmodel.save(out_pkg)
    print("✅ Core ML salvo em:", out_pkg)

    # Salva labels e tokenizer para uso no app (WordPiece no cliente)
    with open(os.path.join(args.out, "labels.json"), "w", encoding="utf-8") as f:
        json.dump(args.labels, f, ensure_ascii=False, indent=2)
    tok.save_pretrained(args.out)  # grava vocab.txt / tokenizer.json
    print("✅ labels.json e tokenizer salvos em:", args.out)

if __name__ == '__main__':
    main()