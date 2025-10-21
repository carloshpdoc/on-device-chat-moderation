# On-Device Chat Moderation

<p align="center">
  <strong>Pipeline completo de moderação de chat para iOS com ML on-device</strong><br>
  Regras + Toxicity Classifier (CoreML) + PII Detection | Zero latência | 100% privado
</p>

---

## Visão Geral

Este projeto entrega uma **solução completa de moderação de chat** para iOS, incluindo:

- **Swift Package (`ChatAICore`)**: Núcleo de moderação reutilizável com regras, PII detection e ML scoring
- **DemoApp**: App iOS de exemplo em SwiftUI
- **Pipeline ML (`ai/`)**: Scripts Python para treinar, avaliar e exportar modelos de toxicidade para CoreML/ONNX

**Principais Features:**
- ✅ **On-device ML**: Toxicity classifier roda 100% local (CoreML)
- ✅ **Regras customizáveis**: Keywords, regex, domínios bloqueados
- ✅ **PII Detection**: Detecta telefone, email, CPF, endereços, Pix, URLs
- ✅ **Off-platform prevention**: Bloqueia tentativas de contato fora do app (WhatsApp, Telegram, etc.)
- ✅ **Multi-categoria**: toxicity, insult, hate, threat, sexual, self_harm
- ✅ **Zero latência**: Sem chamadas de API, tudo local
- ✅ **Privacy-first**: Nenhum dado do usuário sai do dispositivo

## Estrutura do Projeto

```
on-device-chat-moderation/
├─ ChatAICore/                    # Swift Package (biblioteca iOS)
│  ├─ Package.swift
│  └─ Sources/ChatAICore/
│     ├─ Models/                  # Message, ModerationVerdict, ModerationPolicy
│     ├─ Services/                # ModerationService, RuleEngine, ToxicityScoring
│     ├─ ViewModel/               # ChatViewModel
│     └─ Resources/
│        └─ ModerationPolicy.json # Configuração de regras (produção)
│
├─ DemoApp/                       # App iOS de exemplo
│  ├─ ChatAIApp.swift
│  └─ Views/ChatView.swift
│
└─ ai/                            # Pipeline de ML (Python)
   ├─ scripts/
   │  ├─ train.py                 # Treina modelo de toxicidade
   │  ├─ evaluate.py              # Avalia modelo no test set
   │  ├─ export_coreml_ids.py     # Exporta para CoreML
   │  ├─ export_onnx.py           # Exporta para ONNX
   │  └─ suggest_thresholds.py    # Calibra thresholds
   ├─ data/                       # Datasets JSONL (train, valid, test)
   ├─ artifacts/                  # Modelos gerados (CoreML, ONNX, checkpoints)
   ├─ ModerationPolicy.json       # Configuração completa (referência)
   └─ requirements.txt
```

## Quick Start (iOS)

### Opção 1: Rodar o DemoApp (com FakeScorer)

1. **Criar projeto iOS no Xcode**
   ```bash
   # No Xcode: File > New > Project > App (SwiftUI, iOS 15+)
   # Nome: ChatAIModerationDemo
   ```

2. **Adicionar ChatAICore como pacote local**
   - No Xcode: `File > Add Packages...`
   - Clique em `Add Local...` e selecione a pasta `ChatAICore/`
   - Em `Add to Target`, selecione seu app

3. **Copiar código do DemoApp**
   - Copie `DemoApp/Views/ChatView.swift` para seu projeto
   - Substitua o conteúdo de `ChatAIModerationDemoApp.swift` pelo código de `DemoApp/ChatAIApp.swift`
   - Certifique-se de `import ChatAICore` na view

4. **Rodar no Simulator**
   ```bash
   # Command + R (iOS 15+)
   # O app funcionará com FakeScorer (sem ML real)
   ```

### Opção 2: Usar com modelo CoreML real

Depois de treinar o modelo (veja seção [Pipeline de ML](#pipeline-de-ml-treinamento)), siga:

1. **Adicionar o modelo ao app**
   ```bash
   # Arraste ai/artifacts/run1_coreml/ToxicityClassifier.mlpackage para o Xcode
   # Target Membership: marque seu app
   ```

2. **Criar CoreMLScorer**

   Crie `CoreMLScorer.swift` no seu projeto:

   ```swift
   import ChatAICore
   import CoreML

   public struct CoreMLScorer: ToxicityScoring {
       private let model: ToxicityClassifier
       private let labels: [String]

       public init() throws {
           self.model = try ToxicityClassifier(configuration: MLModelConfiguration())
           // Carregar labels do labels.json ou hardcode:
           self.labels = ["toxicity", "insult", "hate", "threat", "sexual", "self_harm"]
       }

       public func score(text: String) throws -> [String: Double] {
           let input = ToxicityClassifierInput(text: text)
           let output = try model.prediction(input: input)

           // Converter output.scores (MLMultiArray) para [String: Double]
           var scores: [String: Double] = [:]
           for (index, label) in labels.enumerated() {
               scores[label] = output.scores[index].doubleValue
           }
           return scores
       }
   }
   ```

3. **Atualizar ChatView.swift**
   ```swift
   // Trocar:
   let scorer = FakeScorer()

   // Por:
   let scorer = try! CoreMLScorer()
   ```

---

## Pipeline de ML (Treinamento)

O diretório `ai/` contém todo o pipeline para treinar e exportar modelos de toxicidade.

### Setup do Ambiente Python

```bash
cd ai/
python -m venv .venv
source .venv/bin/activate  # ou .venv\Scripts\activate no Windows
pip install -r requirements.txt
```

### 1. Preparar Dados

Crie arquivos JSONL em `ai/data/` no formato:

```jsonl
{"text": "você é idiota", "labels": {"toxicity": 1, "insult": 1}}
{"text": "obrigado pela ajuda!", "labels": {"toxicity": 0}}
```

**Categorias suportadas:**
- `toxicity` — Toxicidade geral
- `insult` — Insultos pessoais
- `hate` — Discurso de ódio (racismo, homofobia, etc.)
- `threat` — Ameaças de violência
- `sexual` — Conteúdo sexual inapropriado
- `self_harm` — Automutilação ou suicídio

### 2. Treinar Modelo

```bash
cd ai/
python scripts/train.py \
  --model distilbert-base-multilingual-cased \
  --train data/train.jsonl \
  --valid data/valid.jsonl \
  --output artifacts/run1 \
  --epochs 3 \
  --batch-size 16 \
  --lr 2e-5
```

**Parâmetros principais:**
- `--model`: Base do HuggingFace (padrão: `distilbert-base-multilingual-cased`)
- `--epochs`: Número de épocas de treino
- `--batch-size`: Tamanho do batch
- `--lr`: Learning rate

### 3. Avaliar Modelo

```bash
python scripts/evaluate.py \
  --checkpoint artifacts/run1/checkpoint-6 \
  --test data/test.jsonl
```

Retorna métricas por categoria: accuracy, precision, recall, F1-score.

### 4. Calibrar Thresholds

```bash
python scripts/suggest_thresholds.py \
  --checkpoint artifacts/run1/checkpoint-6 \
  --test data/test.jsonl
```

Sugere thresholds ótimos para cada categoria baseado no F1-score.

### 5. Exportar para CoreML

```bash
python scripts/export_coreml_ids.py \
  --checkpoint artifacts/run1/checkpoint-6 \
  --output artifacts/run1_coreml
```

**Outputs:**
- `ToxicityClassifier.mlpackage` — Modelo CoreML
- `labels.json` — Lista de categorias
- `tokenizer.json`, `vocab.txt` — Tokenizer metadata

### 6. Exportar para ONNX (Android/multi-plataforma)

```bash
python scripts/export_onnx.py \
  --checkpoint artifacts/run1/checkpoint-6 \
  --output artifacts/run1_onnx
```

**Outputs:**
- `model.onnx` — Modelo ONNX para TensorFlow Lite/ONNX Runtime

---

## ModerationPolicy.json — Configuração

O arquivo `ModerationPolicy.json` define todas as regras e thresholds. Existem duas versões:

- **`ChatAICore/Sources/ChatAICore/Resources/ModerationPolicy.json`** — Versão simplificada embedada no app (produção)
- **`ai/ModerationPolicy.json`** — Versão completa com PII patterns e off-platform rules (referência)

### Estrutura da Política

```json
{
  "maxLength": 2000,
  "minToxicity": 0.80,
  "categoriesThresholds": {
    "toxicity": 0.80,
    "insult": 0.75,
    "hate": 0.70,
    "threat": 0.60,
    "sexual": 0.80,
    "self_harm": 0.60
  },
  "blockedKeywords": ["negócio por fora", "pagar fora"],
  "blockedRegex": [
    "(?i)\\b(whats?app|zapzap|zap)\\b",
    "(?i)\\b(telegram)\\b"
  ],
  "blockedDomains": ["wa.me", "t.me", "instagram.com"],
  "piiPatterns": {
    "phoneBR": "(?i)(\\+55\\s?)?(\\(?\\d{2}\\)?\\s?)?(9?\\d{4})[-\\s\\.]?\\d{4}",
    "email": "(?i)[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}",
    "cpf": "\\b\\d{3}\\.\\d{3}\\.\\d{3}-\\d{2}\\b|\\b\\d{11}\\b",
    "pix": "(?i)\\b(chave\\s*pix|pix)\\b",
    "endereco": "(?i)\\b(rua|r\\.|avenida|av\\.)\\s+[\\p{L}0-9 .'-]+\\b\\s*\\d{1,5}"
  },
  "offPlatformKeywords": [
    "me chama no whatsapp",
    "vamos fechar por fora"
  ]
}
```

### Tipos de Regras

#### 1. **Regras Rápidas (Quick Check)**
Executadas ANTES do ML scorer para bloquear instantaneamente:

- **`blockedKeywords`**: Lista de palavras/frases proibidas
- **`blockedRegex`**: Expressões regulares para padrões complexos
- **`blockedDomains`**: Domínios bloqueados (anti-phishing, off-platform)
- **`maxLength`**: Tamanho máximo da mensagem

#### 2. **PII Detection (Informações Pessoais)**
Patterns regex para detectar dados sensíveis:

- **Telefone BR**: `(11) 98765-4321`, `11987654321`, `+55 11 98765-4321`
- **Email**: `usuario@exemplo.com`
- **CPF/CNPJ**: Formatados ou sem pontuação
- **Endereço**: `Rua ABC, 123` / `Av. XYZ, 456`
- **Pix**: `chave pix`, `pix: exemplo@mail.com`
- **CEP**: `12345-678`
- **URLs**: `http://site.com`, `https://exemplo.com/path`

#### 3. **Off-Platform Prevention**
Bloqueia tentativas de tirar conversas do app:

- Keywords: `"me chama no whatsapp"`, `"vamos combinar por fora"`
- Domínios: `wa.me`, `t.me`, `instagram.com/dm`
- Regex: Detecta menções a WhatsApp, Telegram, Instagram

#### 4. **ML-based (Toxicity Thresholds)**
Limites de confiança para cada categoria:

- **`minToxicity`**: Threshold geral de toxicidade (ex: 0.80 = 80%)
- **`categoriesThresholds`**: Limites específicos por categoria

**Exemplo de fluxo:**
```
1. Quick Check (keywords, regex, domínios) → Se bloqueia, retorna imediatamente
2. ML Scoring (ToxicityScoring.score) → Gera [String: Double]
3. Threshold Check → Se score >= threshold, bloqueia
4. Se passou em tudo → Mensagem permitida
```

### Calibrando Thresholds

Use `suggest_thresholds.py` para encontrar valores ótimos:

```bash
python scripts/suggest_thresholds.py \
  --checkpoint artifacts/run1/checkpoint-6 \
  --test data/test.jsonl
```

Output exemplo:
```
Categoria 'toxicity': threshold ótimo = 0.82 (F1=0.89)
Categoria 'insult': threshold ótimo = 0.75 (F1=0.84)
```

---

## Roadmap & Próximos Passos

### ✅ Implementado
- [x] Swift Package modular (`ChatAICore`)
- [x] Pipeline de ML (treino, avaliação, exportação)
- [x] CoreML support
- [x] ONNX export
- [x] PII detection (BR)
- [x] Off-platform prevention
- [x] DemoApp SwiftUI
- [x] Multi-label classification (6 categorias)

### 🚧 Planejado
- [ ] **Android version** (Kotlin + Jetpack Compose + ONNX Runtime)
- [ ] **Tests**: Unit tests para `RuleEngine`, `ModerationService`
- [ ] **CI/CD**: GitHub Actions para treino automático
- [ ] **Telemetria**: Logs agregados (sem PII) para calibração contínua
- [ ] **A/B Testing**: Framework para testar diferentes thresholds
- [ ] **Multilingual**: Suporte a mais idiomas (EN, ES, FR)
- [ ] **Fine-tuning**: Dataset customizado para domínios específicos
- [ ] **Explainability**: Highlight das palavras/scores que causaram bloqueio

---

## Contribuindo

1. Fork o repositório
2. Crie uma branch: `git checkout -b feature/minha-feature`
3. Commit suas mudanças: `git commit -m 'Adiciona nova feature'`
4. Push para a branch: `git push origin feature/minha-feature`
5. Abra um Pull Request

**Guidelines:**
- Siga convenções Swift (SwiftLint)
- Adicione testes para novas features
- Atualize o README se adicionar novas funcionalidades

---

## Licença

MIT License — Veja [LICENSE](LICENSE) para detalhes.

---

## Acknowledgments

**Stack:**
- [distilbert-base-multilingual-cased](https://huggingface.co/distilbert-base-multilingual-cased) — HuggingFace
- [coremltools](https://github.com/apple/coremltools) — Apple
- [ONNX](https://onnx.ai) — Cross-platform ML

**Inspiração:**
- [Perspective API](https://perspectiveapi.com) — Google Jigsaw
- [Detoxify](https://github.com/unitaryai/detoxify) — Unitary AI

---

**Desenvolvido por [Carlos Henrique](https://github.com/carloshpdoc)**
Estrutura SPM limpa, pronta para produção iOS e portável para Android 🚀
