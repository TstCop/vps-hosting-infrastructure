# Vagrant Guide

## Introdução

Este guia fornece instruções sobre como usar o Vagrant para gerenciar ambientes de desenvolvimento e produção em uma infraestrutura de VPS. O Vagrant é uma ferramenta poderosa que permite criar e configurar ambientes de forma rápida e eficiente.

## Pré-requisitos

Antes de começar, certifique-se de que você tenha os seguintes itens instalados:

- [Vagrant](https://www.vagrantup.com/downloads)
- [VirtualBox](https://www.virtualbox.org/)
- [KVM](https://www.linux-kvm.org/)

## Estrutura do Projeto

O projeto está organizado da seguinte forma:

```
vps-hosting-infrastructure/
├── clients/
│   ├── client-001/
│   ├── client-002/
│   └── templates/
├── config/
├── docs/
└── src/
```

### Diretório `clients`

Cada cliente possui seu próprio diretório dentro de `clients/`, contendo um `Vagrantfile` e outros arquivos de configuração. Por exemplo:

- `clients/client-001/Vagrantfile`
- `clients/client-001/config/vm-config.yaml`
- `clients/client-001/scripts/provision.sh`

### Templates

Existem templates disponíveis para facilitar a criação de novos ambientes. Os templates estão localizados em `clients/templates/` e incluem configurações para VMs básicas e servidores web.

## Criando um Novo Ambiente

Para criar um novo ambiente usando Vagrant, siga estas etapas:

1. **Clone o Template**: Copie um dos templates disponíveis para um novo diretório de cliente.
   
   ```bash
   cp -r clients/templates/basic-vm clients/client-003
   ```

2. **Edite o Vagrantfile**: Abra o `Vagrantfile` no diretório do novo cliente e ajuste as configurações conforme necessário.

3. **Configuração da VM**: Edite o arquivo `vm-config.yaml` para definir as configurações específicas da VM.

4. **Provisionamento**: Execute o script de provisionamento para configurar a VM.

   ```bash
   cd clients/client-003
   vagrant up
   ```

## Comandos Úteis

Aqui estão alguns comandos úteis do Vagrant:

- `vagrant up`: Inicia a VM.
- `vagrant halt`: Para a VM.
- `vagrant destroy`: Remove a VM.
- `vagrant reload`: Reinicia a VM e aplica as alterações no Vagrantfile.

## Conclusão

O Vagrant é uma ferramenta essencial para gerenciar ambientes de desenvolvimento e produção. Com a estrutura de diretórios organizada e os templates disponíveis, você pode rapidamente configurar novas VMs para seus clientes. Para mais informações, consulte a [documentação oficial do Vagrant](https://www.vagrantup.com/docs).