# ChatAIModerationDemo — Projeto Xcode Pronto

Este é um projeto Xcode **completo e funcional** que demonstra a integração do `ChatAICore`.

## ✅ O que está incluso:

- ✅ **Projeto Xcode configurado** (`ChatAIModerationDemo.xcodeproj`)
- ✅ **ChatAICore integrado** como Swift Package local
- ✅ **DemoApp compilável** com FakeScorer
- ✅ **Compatível com iOS 15+**
- ✅ **Assets configurados** (AppIcon, AccentColor)

## 🚀 Como rodar:

### 1. Abrir no Xcode

```bash
open ChatAIModerationDemo.xcodeproj
```

### 2. Selecionar Simulator

- No Xcode, clique no seletor de dispositivos (topo, ao lado do botão Stop)
- Escolha qualquer iPhone Simulator (iOS 15+)
- Exemplo: **iPhone 17**, **iPhone 17 Pro**, **iPad Air**

### 3. Rodar

- Pressione **Command + R** ou clique no botão ▶️ (Play)
- O app abrirá no simulador com o chat funcionando

## 📱 O que você verá:

- Interface de chat limpa em SwiftUI
- Input de mensagem com botão "Enviar"
- Moderação funcionando com `FakeScorer` (mock)
- Mensagens bloqueadas aparecem em vermelho abaixo do input

## 🧪 Testando a moderação:

**Mensagens que passam:**
```
"Olá, tudo bem?"
"Obrigado pela ajuda!"
```

**Mensagens que são bloqueadas (FakeScorer):**
```
"vou gritar com você!"  → Detecta "gritar" e aumenta toxicity
```

## 🔧 Próximos Passos:

### 1. Integrar modelo CoreML real

Após treinar o modelo (veja `../ai/`):

1. Arraste `ai/artifacts/run1_coreml/ToxicityClassifier.mlpackage` para o Xcode
2. Crie `CoreMLScorer.swift` (exemplo no README principal)
3. Em `ChatView.swift`, troque:
   ```swift
   let scorer = FakeScorer()  // ← Trocar
   let scorer = try! CoreMLScorer()  // ← Por isso
   ```

### 2. Customizar regras

Edite `ChatAICore/Sources/ChatAICore/Resources/ModerationPolicy.json`:

```json
{
  "blockedKeywords": ["spam", "golpe"],
  "blockedDomains": ["site-ruim.com"],
  "minToxicity": 0.80
}
```

### 3. Adicionar features

- Histórico persistente (Core Data / UserDefaults)
- Avatares dos usuários
- Notificações de mensagens bloqueadas
- Modo escuro customizado

## 🐛 Troubleshooting:

### "ChatAICore" não encontrado
- **Solução:** File → Add Package Dependencies → Add Local → Selecione `../ChatAICore`

### Erro de compilação em `NavigationStack`
- **Causa:** Deployment target < iOS 16
- **Solução:** O código já tem fallback para iOS 15 com `NavigationView`

### Simulator não inicia
- **Solução:** Xcode → Window → Devices and Simulators → Verifique se há simuladores instalados

## 📚 Documentação:

- **README principal:** `../README.md`
- **ChatAICore docs:** `../ChatAICore/`
- **Pipeline ML:** `../ai/README.md` (se existir)

---

**Desenvolvido com Swift 5.9, SwiftUI, iOS 15+**
