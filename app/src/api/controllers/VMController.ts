import { Request, Response } from 'express';
import { VM, ApiResponse } from '../../types';
import { v4 as uuidv4 } from 'uuid';
import { VagrantManager } from '../../lib/vagrant/VagrantManager';

export class VMController {
    private vms: VM[] = [];
    private vagrantManager: VagrantManager;

    constructor() {
        this.vagrantManager = new VagrantManager();
    }

    // RF02.1: Create new VM with template
    async createVM(req: Request, res: Response) {
        try {
            const vmData = req.body;
            const newVM: VM = {
                id: uuidv4(),
                name: vmData.name,
                clientId: vmData.clientId,
                template: vmData.template || 'ubuntu/jammy64',
                status: 'creating',
                config: {
                    cpu: vmData.config?.cpu || 1,
                    memory: vmData.config?.memory || 1024,
                    storage: vmData.config?.storage || 20,
                    network: vmData.config?.network || {}
                },
                createdAt: new Date(),
                updatedAt: new Date(),
                lastAction: 'create',
                metadata: vmData.metadata || {}
            };

            this.vms.push(newVM);

            // Initialize Vagrant environment
            this.vagrantManager.init();
            
            const response: ApiResponse<VM> = {
                success: true,
                data: newVM,
                message: 'VM creation initiated successfully'
            };
            res.status(201).json(response);

            // Simulate VM creation process
            setTimeout(() => {
                const vmIndex = this.vms.findIndex(vm => vm.id === newVM.id);
                if (vmIndex !== -1) {
                    this.vms[vmIndex].status = 'stopped';
                    this.vms[vmIndex].updatedAt = new Date();
                }
            }, 2000);

        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to create VM'
            };
            res.status(500).json(response);
        }
    }

    // Get all VMs
    async getAllVMs(req: Request, res: Response) {
        try {
            const page = parseInt(req.query.page as string) || 1;
            const limit = parseInt(req.query.limit as string) || 10;
            const status = req.query.status as string;
            const clientId = req.query.clientId as string;

            let filteredVMs = this.vms;

            // Filter by status
            if (status) {
                filteredVMs = filteredVMs.filter(vm => vm.status === status);
            }

            // Filter by client
            if (clientId) {
                filteredVMs = filteredVMs.filter(vm => vm.clientId === clientId);
            }

            const startIndex = (page - 1) * limit;
            const endIndex = startIndex + limit;
            const paginatedVMs = filteredVMs.slice(startIndex, endIndex);

            const response: ApiResponse<VM[]> = {
                success: true,
                data: paginatedVMs,
                pagination: {
                    page,
                    limit,
                    total: filteredVMs.length,
                    totalPages: Math.ceil(filteredVMs.length / limit)
                }
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to retrieve VMs'
            };
            res.status(500).json(response);
        }
    }

    // Get VM by ID
    async getVMById(req: Request, res: Response) {
        try {
            const vmId = req.params.id;
            const vm = this.vms.find(vm => vm.id === vmId);
            
            if (!vm) {
                const response: ApiResponse = {
                    success: false,
                    error: 'VM not found'
                };
                res.status(404).json(response);
                return;
            }
            
            const response: ApiResponse<VM> = {
                success: true,
                data: vm
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to retrieve VM'
            };
            res.status(500).json(response);
        }
    }

    // RF02.2: Configure VM (CPU, RAM, storage)
    async updateVM(req: Request, res: Response) {
        try {
            const vmId = req.params.id;
            const updateData = req.body;
            const vmIndex = this.vms.findIndex(vm => vm.id === vmId);
            
            if (vmIndex === -1) {
                const response: ApiResponse = {
                    success: false,
                    error: 'VM not found'
                };
                res.status(404).json(response);
                return;
            }
            
            this.vms[vmIndex] = { 
                ...this.vms[vmIndex], 
                ...updateData, 
                updatedAt: new Date(),
                lastAction: 'configure'
            };
            
            const response: ApiResponse<VM> = {
                success: true,
                data: this.vms[vmIndex],
                message: 'VM configured successfully'
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to configure VM'
            };
            res.status(500).json(response);
        }
    }

    // RF02.3: Start VM
    async startVM(req: Request, res: Response) {
        try {
            const vmId = req.params.id;
            const vmIndex = this.vms.findIndex(vm => vm.id === vmId);
            
            if (vmIndex === -1) {
                const response: ApiResponse = {
                    success: false,
                    error: 'VM not found'
                };
                res.status(404).json(response);
                return;
            }

            const vm = this.vms[vmIndex];
            if (vm.status === 'running') {
                const response: ApiResponse = {
                    success: false,
                    error: 'VM is already running'
                };
                res.status(400).json(response);
                return;
            }

            // Use Vagrant to start VM
            await this.vagrantManager.start(vm.name);
            
            this.vms[vmIndex].status = 'running';
            this.vms[vmIndex].updatedAt = new Date();
            this.vms[vmIndex].lastAction = 'start';
            
            const response: ApiResponse = {
                success: true,
                message: `VM ${vm.name} started successfully`
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to start VM'
            };
            res.status(500).json(response);
        }
    }

    // RF02.4: Stop VM
    async stopVM(req: Request, res: Response) {
        try {
            const vmId = req.params.id;
            const vmIndex = this.vms.findIndex(vm => vm.id === vmId);
            
            if (vmIndex === -1) {
                const response: ApiResponse = {
                    success: false,
                    error: 'VM not found'
                };
                res.status(404).json(response);
                return;
            }

            const vm = this.vms[vmIndex];
            if (vm.status === 'stopped') {
                const response: ApiResponse = {
                    success: false,
                    error: 'VM is already stopped'
                };
                res.status(400).json(response);
                return;
            }

            // Use Vagrant to halt VM
            await this.vagrantManager.halt(vm.name);
            
            this.vms[vmIndex].status = 'stopped';
            this.vms[vmIndex].updatedAt = new Date();
            this.vms[vmIndex].lastAction = 'stop';
            
            const response: ApiResponse = {
                success: true,
                message: `VM ${vm.name} stopped successfully`
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to stop VM'
            };
            res.status(500).json(response);
        }
    }

    // RF02.5: Restart VM
    async restartVM(req: Request, res: Response) {
        try {
            const vmId = req.params.id;
            const vmIndex = this.vms.findIndex(vm => vm.id === vmId);
            
            if (vmIndex === -1) {
                const response: ApiResponse = {
                    success: false,
                    error: 'VM not found'
                };
                res.status(404).json(response);
                return;
            }

            const vm = this.vms[vmIndex];
            
            // Stop then start
            await this.vagrantManager.halt(vm.name);
            await this.vagrantManager.start(vm.name);
            
            this.vms[vmIndex].status = 'running';
            this.vms[vmIndex].updatedAt = new Date();
            this.vms[vmIndex].lastAction = 'restart';
            
            const response: ApiResponse = {
                success: true,
                message: `VM ${vm.name} restarted successfully`
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to restart VM'
            };
            res.status(500).json(response);
        }
    }

    // RF02.6: Suspend VM
    async suspendVM(req: Request, res: Response) {
        try {
            const vmId = req.params.id;
            const vmIndex = this.vms.findIndex(vm => vm.id === vmId);
            
            if (vmIndex === -1) {
                const response: ApiResponse = {
                    success: false,
                    error: 'VM not found'
                };
                res.status(404).json(response);
                return;
            }

            const vm = this.vms[vmIndex];
            
            this.vms[vmIndex].status = 'suspended';
            this.vms[vmIndex].updatedAt = new Date();
            this.vms[vmIndex].lastAction = 'suspend';
            
            const response: ApiResponse = {
                success: true,
                message: `VM ${vm.name} suspended successfully`
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to suspend VM'
            };
            res.status(500).json(response);
        }
    }

    // RF02.7: Resume VM
    async resumeVM(req: Request, res: Response) {
        try {
            const vmId = req.params.id;
            const vmIndex = this.vms.findIndex(vm => vm.id === vmId);
            
            if (vmIndex === -1) {
                const response: ApiResponse = {
                    success: false,
                    error: 'VM not found'
                };
                res.status(404).json(response);
                return;
            }

            const vm = this.vms[vmIndex];
            
            this.vms[vmIndex].status = 'running';
            this.vms[vmIndex].updatedAt = new Date();
            this.vms[vmIndex].lastAction = 'resume';
            
            const response: ApiResponse = {
                success: true,
                message: `VM ${vm.name} resumed successfully`
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to resume VM'
            };
            res.status(500).json(response);
        }
    }

    // RF02.8: Destroy VM
    async deleteVM(req: Request, res: Response) {
        try {
            const vmId = req.params.id;
            const vmIndex = this.vms.findIndex(vm => vm.id === vmId);
            
            if (vmIndex === -1) {
                const response: ApiResponse = {
                    success: false,
                    error: 'VM not found'
                };
                res.status(404).json(response);
                return;
            }

            const vm = this.vms[vmIndex];
            
            // Use Vagrant to destroy VM
            await this.vagrantManager.destroy(vm.name);
            
            this.vms[vmIndex].status = 'destroyed';
            this.vms[vmIndex].updatedAt = new Date();
            this.vms[vmIndex].lastAction = 'destroy';
            
            const response: ApiResponse = {
                success: true,
                message: `VM ${vm.name} destroyed successfully`
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to destroy VM'
            };
            res.status(500).json(response);
        }
    }

    // RF02.9: Clone VM
    async cloneVM(req: Request, res: Response) {
        try {
            const sourceVmId = req.params.id;
            const { name: newName } = req.body;
            
            const sourceVM = this.vms.find(vm => vm.id === sourceVmId);
            if (!sourceVM) {
                const response: ApiResponse = {
                    success: false,
                    error: 'Source VM not found'
                };
                res.status(404).json(response);
                return;
            }

            const clonedVM: VM = {
                ...sourceVM,
                id: uuidv4(),
                name: newName || `${sourceVM.name}-clone`,
                status: 'creating',
                createdAt: new Date(),
                updatedAt: new Date(),
                lastAction: 'clone'
            };

            this.vms.push(clonedVM);
            
            const response: ApiResponse<VM> = {
                success: true,
                data: clonedVM,
                message: 'VM cloned successfully'
            };
            res.status(201).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to clone VM'
            };
            res.status(500).json(response);
        }
    }

    // RF02.10: Create snapshot
    async createSnapshot(req: Request, res: Response) {
        try {
            const vmId = req.params.id;
            const { name: snapshotName } = req.body;
            
            const vm = this.vms.find(vm => vm.id === vmId);
            if (!vm) {
                const response: ApiResponse = {
                    success: false,
                    error: 'VM not found'
                };
                res.status(404).json(response);
                return;
            }

            const snapshot = {
                id: uuidv4(),
                name: snapshotName || `snapshot-${Date.now()}`,
                vmId: vmId,
                createdAt: new Date()
            };
            
            const response: ApiResponse = {
                success: true,
                data: snapshot,
                message: 'Snapshot created successfully'
            };
            res.status(201).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to create snapshot'
            };
            res.status(500).json(response);
        }
    }

    // RF02.11: Restore snapshot
    async restoreSnapshot(req: Request, res: Response) {
        try {
            const vmId = req.params.id;
            const { snapshotId } = req.body;
            
            const vm = this.vms.find(vm => vm.id === vmId);
            if (!vm) {
                const response: ApiResponse = {
                    success: false,
                    error: 'VM not found'
                };
                res.status(404).json(response);
                return;
            }

            const vmIndex = this.vms.findIndex(vm => vm.id === vmId);
            this.vms[vmIndex].updatedAt = new Date();
            this.vms[vmIndex].lastAction = 'restore';
            
            const response: ApiResponse = {
                success: true,
                message: `VM restored from snapshot ${snapshotId}`
            };
            res.status(200).json(response);
        } catch (error) {
            const response: ApiResponse = {
                success: false,
                error: 'Failed to restore snapshot'
            };
            res.status(500).json(response);
        }
    }
}

export default VMController;