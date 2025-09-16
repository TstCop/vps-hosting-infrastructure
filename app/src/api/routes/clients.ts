import { Router } from 'express';
import ClientController from '../controllers/ClientController';

const router = Router();
const clientController = new ClientController();

// RF01.1: Create new client
router.post('/', clientController.createClient.bind(clientController));

// RF01.3: List clients with pagination and filters
router.get('/', clientController.getClients.bind(clientController));

// RF01.4: Get specific client
router.get('/:id', clientController.getClient.bind(clientController));

// RF01.2: Edit existing client
router.put('/:id', clientController.updateClient.bind(clientController));

// RF01.5: Deactivate client (soft delete)
router.delete('/:id', clientController.deleteClient.bind(clientController));

// RF01.6: Get client history
router.get('/:id/history', clientController.getClientHistory.bind(clientController));

export default router;