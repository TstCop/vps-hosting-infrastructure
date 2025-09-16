import { Router } from 'express';
import ClientController from '../controllers/ClientController';

const router = Router();
const clientController = new ClientController();

// Define routes for client-related operations
router.post('/', clientController.createClient.bind(clientController));
router.get('/', clientController.getClients.bind(clientController));
router.get('/:id', clientController.getClient.bind(clientController));
router.put('/:id', clientController.updateClient.bind(clientController));
router.delete('/:id', clientController.deleteClient.bind(clientController));

export default router;