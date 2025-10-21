# DemoApp — Como Rodar

Os arquivos nesta pasta (`ChatAIApp.swift`, `Views/ChatView.swift`) são o código-fonte do app demo,
mas **ainda não estão em um projeto Xcode**.

## Setup Rápido (2 minutos)

### 1. Criar Projeto no Xcode

1. Abra o Xcode
2. **File → New → Project**
3. Escolha:
   - **iOS → App**
   - Interface: **SwiftUI**
   - Minimum Deployment: **iOS 15.0**
   - Nome: `ChatAIModerationDemo` (ou qualquer nome)
4. Salve o projeto **neste diretório** (`ChatAI-OnDeviceModeration/DemoApp/`)

### 2. Adicionar ChatAICore Package

1. No Xcode, selecione o projeto no navigator
2. **File → Add Package Dependencies...**
3. Clique em **Add Local...** (canto inferior esquerdo)
4. Navegue até `ChatAI-OnDeviceModeration/ChatAICore` e selecione
5. Em **Add to Target**, selecione `ChatAIModerationDemo`
6. Clique **Add Package**

### 3. Substituir Código

1. **Substitua** o conteúdo de `ChatAIModerationDemoApp.swift` pelo código de `ChatAIApp.swift` desta pasta
2. **Delete** a ContentView.swift padrão (se houver)
3. **Arraste** o arquivo `Views/ChatView.swift` para o projeto no Xcode
4. Certifique-se de que `import ChatAICore` está presente

### 4. Rodar

1. Selecione um Simulator (iOS 15+)
2. **Command + R** para rodar
3. O app deve abrir com o chat funcionando (usando `FakeScorer`)

---

## Estrutura Esperada (após setup)

```
DemoApp/
├─ ChatAIModerationDemo/
│  ├─ ChatAIModerationDemo.xcodeproj    # Projeto Xcode criado
│  ├─ ChatAIModerationDemo/
│  │  ├─ ChatAIApp.swift                # Copiado deste diretório
│  │  ├─ Views/
│  │  │  └─ ChatView.swift              # Copiado deste diretório
│  │  └─ Assets.xcassets
│  └─ Packages/
│     └─ ChatAICore → ../ChatAICore     # Referência ao package
```

---

## Troubleshooting

### Erro: "No such module 'ChatAICore'"
- Certifique-se de que adicionou o package local em **File → Add Package Dependencies**
- Verifique se `ChatAICore` aparece em **Frameworks, Libraries, and Embedded Content**

### Erro: Build fails com erros de compatibilidade
- Certifique-se de que o **Minimum Deployment Target** está configurado para iOS 15.0:
  - Projeto → General → Minimum Deployments → iOS 15.0

### App compila mas não mostra nada
- Verifique se o `@main` está no arquivo `ChatAIApp.swift`
- Confirme que `ChatView()` está sendo instanciado no `WindowGroup`

---

## Próximos Passos (após funcionar)

1. ✅ App rodando com `FakeScorer`
2. 🔜 Treinar modelo de ML (veja `ai/README.md`)
3. 🔜 Integrar CoreML real (substitua `FakeScorer` por `CoreMLScorer`)

---

**Dica:** Se preferir, use o README principal do repositório para instruções mais detalhadas.
