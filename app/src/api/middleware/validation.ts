export const validateClientData = (req, res, next) => {
    const { name, email } = req.body;
    if (!name || !email) {
        return res.status(400).json({ error: 'Name and email are required.' });
    }
    next();
};

export const validateVMData = (req, res, next) => {
    const { vmName, vmConfig } = req.body;
    if (!vmName || !vmConfig) {
        return res.status(400).json({ error: 'VM name and configuration are required.' });
    }
    next();
};