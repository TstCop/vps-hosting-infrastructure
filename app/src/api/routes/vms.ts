import { Router } from 'express';
import VMController from '../controllers/VMController';

const router = Router();
const vmController = new VMController();

// Define routes for VM-related operations
router.post('/', vmController.createVM.bind(vmController));
router.get('/', vmController.getAllVMs.bind(vmController));
router.get('/:id', vmController.getVMById.bind(vmController));
router.put('/:id', vmController.updateVM.bind(vmController));
router.delete('/:id', vmController.deleteVM.bind(vmController));
router.post('/:id/start', vmController.startVM.bind(vmController));
router.post('/:id/stop', vmController.stopVM.bind(vmController));

export default router;