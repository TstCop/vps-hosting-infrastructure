import { Router } from 'express';
import clientRoutes from './clients';
import vmRoutes from './vms';

const router = Router();

router.use('/clients', clientRoutes);
router.use('/vms', vmRoutes);

export default router;