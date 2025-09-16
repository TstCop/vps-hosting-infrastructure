import request from 'supertest';
import app from '../../src/api/app';

describe('API Integration Tests', () => {
  it('should return a list of clients', async () => {
    const response = await request(app).get('/api/clients');
    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
  });

  it('should create a new client', async () => {
    const newClient = { name: 'Client Test', email: 'client@test.com' };
    const response = await request(app).post('/api/clients').send(newClient);
    expect(response.status).toBe(201);
    expect(response.body.name).toBe(newClient.name);
  });

  it('should return a specific client', async () => {
    const response = await request(app).get('/api/clients/1');
    expect(response.status).toBe(200);
    expect(response.body.id).toBe(1);
  });

  it('should update an existing client', async () => {
    const updatedClient = { name: 'Updated Client' };
    const response = await request(app).put('/api/clients/1').send(updatedClient);
    expect(response.status).toBe(200);
    expect(response.body.name).toBe(updatedClient.name);
  });

  it('should delete a client', async () => {
    const response = await request(app).delete('/api/clients/1');
    expect(response.status).toBe(204);
  });

  it('should return a list of VMs', async () => {
    const response = await request(app).get('/api/vms');
    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
  });

  it('should create a new VM', async () => {
    const newVM = { name: 'VM Test', clientId: 1 };
    const response = await request(app).post('/api/vms').send(newVM);
    expect(response.status).toBe(201);
    expect(response.body.name).toBe(newVM.name);
  });

  it('should return a specific VM', async () => {
    const response = await request(app).get('/api/vms/1');
    expect(response.status).toBe(200);
    expect(response.body.id).toBe(1);
  });

  it('should update an existing VM', async () => {
    const updatedVM = { name: 'Updated VM' };
    const response = await request(app).put('/api/vms/1').send(updatedVM);
    expect(response.status).toBe(200);
    expect(response.body.name).toBe(updatedVM.name);
  });

  it('should delete a VM', async () => {
    const response = await request(app).delete('/api/vms/1');
    expect(response.status).toBe(204);
  });
});