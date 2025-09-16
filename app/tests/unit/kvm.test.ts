import { KVMManager } from '../../src/lib/kvm/KVMManager';

describe('KVMManager', () => {
    let kvmManager: KVMManager;

    beforeEach(() => {
        kvmManager = new KVMManager();
    });

    test('should create a new VM', async () => {
        const vmConfig = {
            name: 'test-vm',
            memory: 2048,
            cpus: 2,
            disk: 20,
        };
        const result = await kvmManager.createVM(vmConfig);
        expect(result).toBe('VM created');
    });

    test('should start a VM', async () => {
        const vmId = 'test-vm-id';
        const result = await kvmManager.startVM(vmId);
        expect(result).toBe('VM started');
    });

    test('should stop a VM', async () => {
        const vmId = 'test-vm-id';
        const result = await kvmManager.stopVM(vmId);
        expect(result).toBe('VM stopped');
    });

    test('should destroy a VM', async () => {
        const vmId = 'test-vm-id';
        const result = await kvmManager.destroyVM(vmId);
        expect(result).toBe('VM destroyed');
    });
});