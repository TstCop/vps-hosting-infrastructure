# Documentação do Cliente 002

Este diretório contém a documentação específica para o cliente 002, incluindo informações sobre a configuração e o gerenciamento do ambiente virtual.

## Estrutura do Diretório

- **Vagrantfile**: Define a configuração da máquina virtual para o cliente 002.
- **config/vm-config.yaml**: Contém as configurações específicas da máquina virtual.
- **scripts/provision.sh**: Script para provisionar o ambiente da máquina virtual.
- **scripts/setup.sh**: Script para configurar o ambiente do cliente 002.

## Instruções de Uso

1. **Provisionar a Máquina Virtual**:
   Execute o script `provision.sh` para configurar a máquina virtual de acordo com as especificações definidas no `Vagrantfile`.

   ```bash
   ./scripts/provision.sh
   ```

2. **Configurar o Ambiente**:
   Após o provisionamento, execute o script `setup.sh` para realizar a configuração adicional necessária.

   ```bash
   ./scripts/setup.sh
   ```

## Notas

- Certifique-se de ter o Vagrant e o KVM instalados e configurados corretamente antes de executar os scripts.
- Consulte o arquivo `config/vm-config.yaml` para ajustes específicos na configuração da máquina virtual.

---

*Este README é atualizado conforme necessário para refletir as mudanças no ambiente do cliente.*