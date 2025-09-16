# VPS Hosting Infrastructure Project

Este projeto é uma infraestrutura para gerenciar Vagrant e KVM para uma empresa de hospedagem de VPS. Ele fornece uma estrutura organizada para gerenciar clientes, máquinas virtuais e suas respectivas configurações.

## Estrutura do Projeto

- **src/**: Contém o código-fonte da aplicação.
  - **api/**: Implementação da API, incluindo controladores, rotas e middleware.
  - **lib/**: Bibliotecas para gerenciar Vagrant, KVM e conexão com o banco de dados.
  - **scripts/**: Scripts utilitários para provisionamento, backup e limpeza.
  - **types/**: Tipos personalizados utilizados na aplicação.

- **clients/**: Diretório onde cada cliente tem sua própria estrutura.
  - **client-001/**: Diretório para o cliente 001, contendo seu Vagrantfile e configurações.
  - **client-002/**: Diretório para o cliente 002, contendo seu Vagrantfile e configurações.
  - **templates/**: Modelos de Vagrantfiles e configurações para diferentes tipos de máquinas virtuais.

- **config/**: Arquivos de configuração para o banco de dados, KVM, rede e Vagrant.

- **docs/**: Documentação do projeto, incluindo guias e instruções de uso.

- **tests/**: Testes unitários e de integração para garantir a qualidade do código.

- **package.json**: Configuração do npm, listando dependências e scripts do projeto.

- **tsconfig.json**: Configuração do TypeScript, especificando opções do compilador.

- **docker-compose.yml**: Define serviços para contêineres Docker.

- **Dockerfile**: Instruções para construir uma imagem Docker.

## Como Usar

1. Clone o repositório.
2. Instale as dependências usando `npm install`.
3. Configure os arquivos de configuração conforme necessário.
4. Utilize os scripts em `src/scripts/` para gerenciar o ambiente.
5. Adicione novos clientes no diretório `clients/` conforme necessário.

## Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests.

## Licença

Este projeto está licenciado sob a MIT License - veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

*Este README é atualizado automaticamente quando novos arquivos de documentação são adicionados.*