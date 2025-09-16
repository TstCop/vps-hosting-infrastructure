import { VagrantManager } from '../../src/lib/vagrant/VagrantManager';

describe('VagrantManager', () => {
    let vagrantManager: VagrantManager;

    beforeEach(() => {
        vagrantManager = new VagrantManager();
    });

    test('should initialize Vagrant environment', () => {
        const result = vagrantManager.init();
        expect(result).toBeTruthy();
    });

    test('should create a new Vagrantfile', () => {
        const config = { name: 'test-vm', box: 'ubuntu/bionic64' };
        const result = vagrantManager.createVagrantfile(config);
        expect(result).toContain('Vagrant.configure("2") do |config|');
        expect(result).toContain('config.vm.box = "ubuntu/bionic64"');
    });

    test('should start the VM', async () => {
        const result = await vagrantManager.start('test-vm');
        expect(result).toBe('VM started');
    });

    test('should halt the VM', async () => {
        const result = await vagrantManager.halt('test-vm');
        expect(result).toBe('VM halted');
    });

    test('should destroy the VM', async () => {
        const result = await vagrantManager.destroy('test-vm');
        expect(result).toBe('VM destroyed');
    });
});