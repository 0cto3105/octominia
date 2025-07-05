// backend/middleware/authMiddleware.js
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
  let token;

  // Vérifie si un token est présent dans l'en-tête Authorization (Bearer Token)
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // Extraire le token (ignorer "Bearer ")
      token = req.headers.authorization.split(' ')[1];

      // Vérifier le token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Trouver l'utilisateur par l'ID dans le token et l'attacher à la requête
      // Assurez-vous que le champ 'role' est bien inclus ici pour les vérifications futures
      req.user = await User.findById(decoded.id).select('-password'); // Exclut le mot de passe du retour

      next(); // Passer au middleware ou à la route suivante
    } catch (error) {
      console.error(error);
      res.status(401).json({ message: 'Pas autorisé, token invalide' });
    }
  } else { // Ajout d'un else pour gérer le cas où il n'y a pas de token du tout
    res.status(401).json({ message: 'Pas autorisé, pas de token' });
  }
};

// --- NOUVELLE FONCTION MIDDLEWARE POUR L'AUTORISATION PAR RÔLE ---
/**
 * Middleware qui restreint l'accès aux routes en fonction des rôles des utilisateurs.
 * Utilisation: `router.get('/admin', protect, authorizeRoles('admin'), adminControllerFunction);`
 * ou pour plusieurs rôles: `router.post('/moderated', protect, authorizeRoles('admin', 'user'), moderatedFunction);`
 *
 * @param  {...string} roles - Liste des rôles autorisés pour accéder à la route (ex: 'admin', 'user', 'guest')
 */
const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    // Vérifie si req.user existe (middleware protect doit avoir été exécuté avant)
    // et si req.user.role est défini et est inclus dans les rôles autorisés
    if (!req.user || !req.user.role || !roles.includes(req.user.role)) {
      // Si l'utilisateur n'a pas un rôle autorisé, renvoyer une erreur 403 Forbidden
      return res.status(403).json({
        message: `Accès refusé. Vous n'avez pas le rôle requis. Rôles autorisés: ${roles.join(', ')}.`
      });
    }
    // Si l'utilisateur a un rôle autorisé, passer au middleware/contrôleur suivant
    next();
  };
};
// ------------------------------------------------------------------

module.exports = { protect, authorizeRoles }; // Exporte les deux middlewares