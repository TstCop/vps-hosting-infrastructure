import {
  Add as AddIcon,
  Code as CodeIcon
} from '@mui/icons-material';
import {
  Box,
  Button,
  Card,
  CardActions,
  CardContent,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  Step,
  StepContent,
  StepLabel,
  Stepper,
  TextField,
  Typography
} from '@mui/material';
import React, { useState } from 'react';

interface Template {
  id: string;
  name: string;
  category: string;
  description: string;
  os: string;
  version: string;
  cpu: number;
  memory: number;
  disk: number;
  popular: boolean;
}

const mockTemplates: Template[] = [
  {
    id: '1',
    name: 'Ubuntu Server',
    category: 'OS Base',
    description: 'Ubuntu 22.04 LTS com configurações otimizadas para servidor',
    os: 'Ubuntu',
    version: '22.04 LTS',
    cpu: 2,
    memory: 4,
    disk: 40,
    popular: true
  },
  {
    id: '2',
    name: 'NGINX Web Server',
    category: 'Web Server',
    description: 'Servidor web NGINX configurado com SSL e otimizações',
    os: 'Ubuntu',
    version: '22.04 LTS',
    cpu: 2,
    memory: 4,
    disk: 40,
    popular: true
  },
  {
    id: '3',
    name: 'GitLab CE',
    category: 'DevOps',
    description: 'GitLab Community Edition com CI/CD configurado',
    os: 'Ubuntu',
    version: '22.04 LTS',
    cpu: 4,
    memory: 8,
    disk: 80,
    popular: false
  }
];

const Templates: React.FC = () => {
  const [templates] = useState<Template[]>(mockTemplates);
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [openDetailDialog, setOpenDetailDialog] = useState(false);
  const [openDeployDialog, setOpenDeployDialog] = useState(false);
  const [selectedTemplate, setSelectedTemplate] = useState<Template | null>(null);
  const [activeStep, setActiveStep] = useState(0);

  const categories = Array.from(new Set(templates.map(t => t.category)));

  const filteredTemplates = categoryFilter === 'all'
    ? templates
    : templates.filter(t => t.category === categoryFilter);

  const handleViewTemplate = (template: Template) => {
    setSelectedTemplate(template);
    setOpenDetailDialog(true);
  };

  const handleDeployTemplate = (template: Template) => {
    setSelectedTemplate(template);
    setOpenDeployDialog(true);
    setActiveStep(0);
  };

  const deploySteps = [
    'Configurações Básicas',
    'Recursos da VM',
    'Rede e Segurança',
    'Confirmação'
  ];

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <CodeIcon />
          Templates
        </Typography>
        <Button variant="outlined" startIcon={<AddIcon />}>
          Criar Template
        </Button>
      </Box>

      {/* Category Filter */}
      <Box sx={{ mb: 3 }}>
        <FormControl size="small" sx={{ minWidth: 200 }}>
          <InputLabel>Categoria</InputLabel>
          <Select
            value={categoryFilter}
            label="Categoria"
            onChange={(e) => setCategoryFilter(e.target.value)}
          >
            <MenuItem value="all">Todas as Categorias</MenuItem>
            {categories.map(category => (
              <MenuItem key={category} value={category}>{category}</MenuItem>
            ))}
          </Select>
        </FormControl>
      </Box>

      {/* Quick Stats */}
      <Box sx={{ display: 'flex', gap: 2, mb: 4 }}>
        <Card sx={{ flex: 1 }}>
          <CardContent>
            <Typography variant="h6" color="primary">
              {templates.length}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Templates Disponíveis
            </Typography>
          </CardContent>
        </Card>

        <Card sx={{ flex: 1 }}>
          <CardContent>
            <Typography variant="h6" color="secondary">
              {templates.filter(t => t.popular).length}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Templates Populares
            </Typography>
          </CardContent>
        </Card>

        <Card sx={{ flex: 1 }}>
          <CardContent>
            <Typography variant="h6" color="info.main">
              {categories.length}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Categorias
            </Typography>
          </CardContent>
        </Card>
      </Box>

      {/* Templates Grid */}
      <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
        {filteredTemplates.map((template) => (
          <Card key={template.id} sx={{ minWidth: 300, maxWidth: 350, flex: '1 1 300px' }}>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                <Typography variant="h6" component="div">
                  {template.name}
                </Typography>
                {template.popular && (
                  <Chip label="Popular" color="primary" size="small" />
                )}
              </Box>

              <Chip label={template.category} variant="outlined" size="small" sx={{ mb: 2 }} />

              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                {template.description}
              </Typography>

              <Box sx={{ mb: 2 }}>
                <Typography variant="body2" color="text.secondary">
                  <strong>OS:</strong> {template.os} {template.version}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  <strong>Recursos:</strong> {template.cpu} vCPU, {template.memory} GB RAM, {template.disk} GB
                </Typography>
              </Box>
            </CardContent>
            <CardActions>
              <Button size="small" onClick={() => handleViewTemplate(template)}>
                Detalhes
              </Button>
              <Button
                size="small"
                variant="contained"
                onClick={() => handleDeployTemplate(template)}
              >
                Deploy
              </Button>
            </CardActions>
          </Card>
        ))}
      </Box>

      {/* Template Details Dialog */}
      <Dialog
        open={openDetailDialog}
        onClose={() => setOpenDetailDialog(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Detalhes do Template</DialogTitle>
        <DialogContent>
          {selectedTemplate && (
            <Box sx={{ mt: 2 }}>
              <Typography variant="h6" gutterBottom>{selectedTemplate.name}</Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                {selectedTemplate.description}
              </Typography>

              <Typography variant="subtitle2" gutterBottom>Especificações:</Typography>
              <Typography variant="body2">Sistema Operacional: {selectedTemplate.os} {selectedTemplate.version}</Typography>
              <Typography variant="body2">CPU: {selectedTemplate.cpu} vCPUs</Typography>
              <Typography variant="body2">Memória: {selectedTemplate.memory} GB</Typography>
              <Typography variant="body2">Disco: {selectedTemplate.disk} GB</Typography>
              <Typography variant="body2">Categoria: {selectedTemplate.category}</Typography>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDetailDialog(false)}>Fechar</Button>
          <Button
            variant="contained"
            onClick={() => {
              setOpenDetailDialog(false);
              if (selectedTemplate) handleDeployTemplate(selectedTemplate);
            }}
          >
            Deploy
          </Button>
        </DialogActions>
      </Dialog>

      {/* Deploy Dialog */}
      <Dialog
        open={openDeployDialog}
        onClose={() => setOpenDeployDialog(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          Deploy: {selectedTemplate?.name}
        </DialogTitle>
        <DialogContent>
          <Stepper activeStep={activeStep} orientation="vertical" sx={{ mt: 2 }}>
            {deploySteps.map((label, index) => (
              <Step key={label}>
                <StepLabel>{label}</StepLabel>
                <StepContent>
                  {index === 0 && (
                    <Box sx={{ display: 'flex', gap: 2, flexDirection: 'column' }}>
                      <TextField
                        fullWidth
                        label="Nome da VM"
                        placeholder="Ex: nginx-app-01"
                      />
                      <TextField
                        fullWidth
                        select
                        label="Cliente"
                        defaultValue=""
                      >
                        <MenuItem value="client-a">Cliente A</MenuItem>
                        <MenuItem value="client-b">Cliente B</MenuItem>
                      </TextField>
                    </Box>
                  )}

                  {index === 1 && (
                    <Box sx={{ display: 'flex', gap: 2, flexDirection: 'column' }}>
                      <TextField
                        fullWidth
                        type="number"
                        label="CPU (vCPUs)"
                        defaultValue={selectedTemplate?.cpu}
                      />
                      <TextField
                        fullWidth
                        type="number"
                        label="Memória (GB)"
                        defaultValue={selectedTemplate?.memory}
                      />
                      <TextField
                        fullWidth
                        type="number"
                        label="Disco (GB)"
                        defaultValue={selectedTemplate?.disk}
                      />
                    </Box>
                  )}

                  {index === 2 && (
                    <Box sx={{ display: 'flex', gap: 2, flexDirection: 'column' }}>
                      <TextField
                        fullWidth
                        label="Rede"
                        defaultValue="default"
                      />
                      <TextField
                        fullWidth
                        label="Firewall"
                        defaultValue="default"
                      />
                    </Box>
                  )}

                  {index === 3 && (
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Revise as configurações antes de confirmar o deploy.
                      </Typography>
                    </Box>
                  )}

                  <Box sx={{ mt: 2 }}>
                    <Button
                      variant="contained"
                      onClick={() => setActiveStep(activeStep + 1)}
                      sx={{ mr: 1 }}
                      disabled={activeStep === deploySteps.length - 1}
                    >
                      {activeStep === deploySteps.length - 1 ? 'Finalizar' : 'Continuar'}
                    </Button>
                    <Button
                      disabled={activeStep === 0}
                      onClick={() => setActiveStep(activeStep - 1)}
                    >
                      Voltar
                    </Button>
                  </Box>
                </StepContent>
              </Step>
            ))}
          </Stepper>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDeployDialog(false)}>Cancelar</Button>
          {activeStep === deploySteps.length - 1 && (
            <Button variant="contained">Confirmar Deploy</Button>
          )}
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Templates;
