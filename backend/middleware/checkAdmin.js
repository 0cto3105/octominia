// backend/middleware/check-admin.js
module.exports = (req, res, next) => {
  try {
    const token = req.headers.authorization.split(" ")[1];
    const decodedToken = jwt.verify(token, process.env.JWT_KEY || 'super_secret_key_dev');
    if (decodedToken.role !== 'admin') { // Vérifie le rôle
      return res.status(403).json({ message: 'Accès non autorisé. Seuls les administrateurs peuvent effectuer cette action.' });
    }
    req.userData = { email: decodedToken.email, userId: decodedToken.userId, role: decodedToken.role };
    next();
  } catch (error) {
    res.status(401).json({ message: 'Vous n\'êtes pas authentifié !' });
  }
};