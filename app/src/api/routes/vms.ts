import { Router } from 'express';
import VMController from '../controllers/VMController';

const router = Router();
const vmController = new VMController();

// RF02.1: Create new VM with template
router.post('/', vmController.createVM.bind(vmController));

// Get all VMs with filtering and pagination
router.get('/', vmController.getAllVMs.bind(vmController));

// Get specific VM
router.get('/:id', vmController.getVMById.bind(vmController));

// RF02.2: Configure VM (CPU, RAM, storage)
router.put('/:id', vmController.updateVM.bind(vmController));

// RF02.3: Start VM
router.post('/:id/start', vmController.startVM.bind(vmController));

// RF02.4: Stop VM
router.post('/:id/stop', vmController.stopVM.bind(vmController));

// RF02.5: Restart VM
router.post('/:id/restart', vmController.restartVM.bind(vmController));

// RF02.6: Suspend VM
router.post('/:id/suspend', vmController.suspendVM.bind(vmController));

// RF02.7: Resume VM
router.post('/:id/resume', vmController.resumeVM.bind(vmController));

// RF02.8: Destroy VM
router.delete('/:id', vmController.deleteVM.bind(vmController));

// RF02.9: Clone VM
router.post('/:id/clone', vmController.cloneVM.bind(vmController));

// RF02.10: Create snapshot
router.post('/:id/snapshot', vmController.createSnapshot.bind(vmController));

// RF02.11: Restore snapshot
router.post('/:id/restore', vmController.restoreSnapshot.bind(vmController));

export default router;