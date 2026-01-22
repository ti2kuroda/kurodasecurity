# 🛡️ Kuroda Security

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![GetX](https://img.shields.io/badge/GetX-%238C20B2.svg?style=for-the-badge&logo=getx&logoColor=white)

O **Kuroda Security** é um aplicativo de monitoramento e gestão de ativos de segurança desenvolvido em Flutter. Ele atua como uma ponte inteligente entre servidores de armazenamento local (**Windows Samba**) e controle em nuvem (**Firebase Firestore**), permitindo a visualização de mídia de segurança sem comprometer o armazenamento físico do dispositivo móvel.

---

## 🚀 Diferenciais do Projeto

### 📂 Gestão de Mídia Híbrida (Samba + Cache)
O app conecta-se diretamente a um servidor Windows via protocolo **Samba (SMB)**. Para otimizar a performance:

* **Streaming & Cache Temporário:** Os vídeos e imagens são baixados para uma área temporária do app apenas durante a visualização.
* **Auto-Cleanup:** Ao encerrar o aplicativo, todos os arquivos temporários são eliminados, garantindo que o consumo de memória do celular seja mínimo.



### ☁️ Inteligência Firebase (Firestore & Auth)
Enquanto os arquivos pesados ficam no servidor local, a inteligência reside no Firebase:

* **Metadados:** O Firestore armazena apenas os diretórios (caminhos de rede), descrições e metadados das mídias.
* **Rastreamento de Atividades:** Logs detalhados de quem acessou, visualizou ou modificou registros.
* **Exclusão Lógica (Soft Delete):** Itens "excluídos" no app não são apagados do banco de dados imediatamente. Eles são apenas desativados e ocultados da interface, mantendo o histórico de **quem e quando** realizou a exclusão para fins de auditoria.

---

## 🏗️ Arquitetura Técnica

* **Framework:** Flutter com **Layout Responsivo** (Adaptável para tablets de monitoramento e smartphones).
* **Gerenciamento de Estado:** [GetX](https://pub.dev/packages/get).
* **Padrão de Arquitetura:** **Get Pattern** (Separação estrita entre Data, Controller e View).
* **Autenticação:** Firebase com níveis de acesso.
* **Integração de Rede:** Cliente SMB para comunicação com Windows Server.

---

## 🛠️ Estrutura de Pastas

```text
lib/
 ├── app/
 │    ├── data/              # Providers e Repositories (Firebase & Samba)
 │    ├── models/            # Modelos de dados (Mídias, Logs, Usuários)
 │    ├── modules/           # Módulos de Câmeras, Logs e Autenticação
 │    │    └── widgets/      # Componentes específicos dos módulos
 │    └── routes/            # Gerenciamento de rotas e navegação GetX

 
 └── main.dart               # Ponto de entrada da aplicação
````
---

## 📋 Requisitos de Configuração

1. **Servidor Windows:** O servidor Samba deve estar acessível na mesma rede ou via VPN, com as permissões de leitura/escrita configuradas para o usuário do app.
2. **Firebase:** É necessário configurar o projeto no console do Firebase e baixar o arquivo `google-services.json` para o diretório `android/app/`.
3. **Configurações de Rede:** No Android, certifique-se de que as permissões de rede e `usesCleartextTraffic` estejam configuradas no `AndroidManifest.xml` caso o servidor local não utilize SSL.

---

## 🔐 Segurança e Auditoria

O **Kuroda Security** foca na transparência e integridade dos dados:

* **Logs de Auditoria:** Cada ação de "exclusão" gera um rastro no Firestore contendo o ID do usuário e o *timestamp* exato da operação.
* **Isolamento de Dados:** Nenhuma mídia de segurança é exposta à nuvem pública; apenas as referências de caminho de rede local são armazenadas, garantindo a total privacidade das imagens da loja.

---

> ⭐ *Desenvolvido para garantir a integridade e o monitoramento eficiente da **M. S. KURODA E CIA LTDA.***
