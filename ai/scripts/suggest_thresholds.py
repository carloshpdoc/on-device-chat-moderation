import argparse, json, numpy as np
from sklearn.metrics import f1_score

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--probs', required=True, help='arquivo .npz com probs (gerado pelo evaluate.py)')
    ap.add_argument('--ytrue', required=True, help='arquivo .npz com y_true (gerado pelo evaluate.py)')
    ap.add_argument('--labels', nargs='+', required=True, help='ordem dos rótulos usada no treino')
    ap.add_argument('--metric', choices=['macro_f1','micro_f1'], default='macro_f1')
    ap.add_argument('--out', required=True, help='caminho do JSON de saída com os thresholds')
    args = ap.parse_args()

    probs = np.load(args.probs)['probs']   # shape: [N, C]
    y_true = np.load(args.ytrue)['y']      # shape: [N, C]

    thresholds = {}
    grid = np.linspace(0.1, 0.9, 81)

    # Global
    best_global, best_score = 0.5, -1.0
    for t in grid:
        y_pred = (probs >= t).astype(int)
        score = f1_score(y_true, y_pred, average='macro' if args.metric=='macro_f1' else 'micro', zero_division=0)
        if score > best_score:
            best_score, best_global = score, float(t)
    thresholds['__global__'] = best_global

    # Por rótulo
    for i, name in enumerate(args.labels):
        best_t, best_s = 0.5, -1.0
        for t in grid:
            s = f1_score(y_true[:, i], (probs[:, i] >= t).astype(int), average='binary', zero_division=0)
            if s > best_s:
                best_s, best_t = s, float(t)
        thresholds[name] = best_t

    with open(args.out, 'w', encoding='utf-8') as f:
        json.dump(thresholds, f, ensure_ascii=False, indent=2)

    print("Thresholds sugeridos:")
    print(json.dumps(thresholds, indent=2, ensure_ascii=False))

if __name__ == '__main__':
    main()