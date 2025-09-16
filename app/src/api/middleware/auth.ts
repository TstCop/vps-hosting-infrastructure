export const authenticate = (req, res, next) => {
    const token = req.headers['authorization'];

    if (!token) {
        return res.status(401).json({ message: 'No token provided' });
    }

    // Verify token logic here (e.g., using JWT)
    // If valid, proceed to the next middleware
    // If invalid, return a 403 status

    next();
};

export const authorize = (roles = []) => {
    return (req, res, next) => {
        // Check user role logic here
        // If user role is in the allowed roles, proceed
        // If not, return a 403 status

        next();
    };
};