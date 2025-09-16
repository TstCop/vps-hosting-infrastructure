import request from 'supertest';
import app from '../../src/api/app';

describe('API Integration Tests', () => {
  let createdClientId: string;
  let createdVMId: string;

  it('should return a list of clients', async () => {
    const response = await request(app).get('/api/clients');
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(Array.isArray(response.body.data)).toBe(true);
  });

  it('should create a new client', async () => {
    const newClient = { name: 'Client Test', email: 'client@test.com' };
    const response = await request(app).post('/api/clients').send(newClient);
    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
    expect(response.body.data.name).toBe(newClient.name);
    expect(response.body.data.email).toBe(newClient.email);
    createdClientId = response.body.data.id;
  });

  it('should return a specific client', async () => {
    const response = await request(app).get(`/api/clients/${createdClientId}`);
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.id).toBe(createdClientId);
  });

  it('should update an existing client', async () => {
    const updatedClient = { name: 'Updated Client' };
    const response = await request(app).put(`/api/clients/${createdClientId}`).send(updatedClient);
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.name).toBe(updatedClient.name);
  });

  it('should return a list of VMs', async () => {
    const response = await request(app).get('/api/vms');
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(Array.isArray(response.body.data)).toBe(true);
  });

  it('should create a new VM', async () => {
    const newVM = { name: 'VM Test', clientId: createdClientId };
    const response = await request(app).post('/api/vms').send(newVM);
    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
    expect(response.body.data.name).toBe(newVM.name);
    expect(response.body.data.clientId).toBe(newVM.clientId);
    createdVMId = response.body.data.id;
  });

  it('should return a specific VM', async () => {
    const response = await request(app).get(`/api/vms/${createdVMId}`);
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.id).toBe(createdVMId);
  });

  it('should update an existing VM', async () => {
    const updatedVM = { name: 'Updated VM' };
    const response = await request(app).put(`/api/vms/${createdVMId}`).send(updatedVM);
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.name).toBe(updatedVM.name);
  });

  it('should delete a VM', async () => {
    const response = await request(app).delete(`/api/vms/${createdVMId}`);
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
  });

  it('should deactivate a client', async () => {
    const response = await request(app).delete(`/api/clients/${createdClientId}`);
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
  });
});