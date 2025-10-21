
# ChatAI — Moderação On-Device (iOS, pronto para Android)

Este pacote entrega o **núcleo SPM (`ChatAICore`)** com pipeline de moderação local
(regras + scorer on-device) e um **DemoApp** em SwiftUI que consome o núcleo.
Por padrão o DemoApp usa `FakeScorer` (sem ML) para você validar UX/fluxo.
Depois é só plugar seu `.mlmodel` implementando `ToxicityScoring`.

## Estrutura
```
ChatAI-OnDeviceModeration/
├─ ChatAICore/             # Swift Package (library)
│  ├─ Package.swift
│  └─ Sources/ChatAICore/
│     ├─ Models/
│     ├─ Services/
│     ├─ ViewModel/
│     └─ Resources/ModerationPolicy.json
└─ DemoApp/                # Código-fonte do app iOS (adicione a um projeto Xcode)
   ├─ ChatAIApp.swift
   └─ Views/ChatView.swift
```

## Como rodar no Xcode (rápido)
1. Abra o Xcode e crie um novo projeto iOS (App, SwiftUI, iOS 16+), ex.: **ChatAIApp**.
2. No projeto, vá em **File > Add Packages…** e adicione o pacote local `ChatAICore`:
   - Clique em **Add Local...** e selecione a pasta `ChatAICore` deste repositório.
   - Em **Add to Target**, selecione o seu app.
3. No seu app, crie o arquivo `ChatView.swift` (ou copie de `DemoApp/Views/ChatView.swift`) e o `ChatAIApp.swift`
   (copie de `DemoApp/ChatAIApp.swift`). Certifique-se de **import ChatAICore** na View.
4. Rode no Simulator (iOS 16+). O fluxo já funciona com `FakeScorer`.

> Dica: se preferir, você pode simplesmente **copiar a pasta `DemoApp/`** para dentro do seu projeto Xcode existente
e ajustar os namespaces. O essencial é **adicionar o pacote** `ChatAICore` ao projeto.

## Plugando um modelo .mlmodel (Core ML)
1. Treine/importe um classificador e adicione-o ao **target do App** (não ao pacote).
2. Implemente um tipo que conforma `ToxicityScoring` (ex.: `CoreMLScorer`) chamando seu `model.prediction(...)`
   e retornando `Map<String, Double>` (ex.: `{ "toxicity": 0.12, "insult": 0.02 }`).
3. No `ChatView`, troque `FakeScorer()` por `CoreMLScorer()`.
4. Ajuste thresholds no `ChatAICore/Sources/ChatAICore/Resources/ModerationPolicy.json`.

### Exemplo de assinatura esperada
```swift
public struct CoreMLScorer: ToxicityScoring {
    public init() { /* carregar o modelo aqui */ }
    public func score(text: String) throws -> [String : Double] {
        // chamar seu modelo e devolver probabilidades por rótulo
    }
}
```

## Android (futuro)
- Reuse `ModerationPolicy.json` e a semântica das regras.
- Implemente um scorer com **TensorFlow Lite** ou **ONNX Runtime Mobile**.
- UI com Jetpack Compose espelhando a UX do iOS.

## Política e Telemetria
- O arquivo `ModerationPolicy.json` define palavras, regex, domínios e limites.
- Recomendo log local **sem conteúdo do usuário** (apenas contagens por categoria) para calibrar thresholds.

---

Feito para o Carlos HP: estrutura SPM limpa, pronta para plugar Core ML e portar para Android 👍
