// backend/routes/users.js (ou un nouveau fichier de routes pour l'admin)
const express = require('express');
const router = express.Router();
const User = require('../models/User');
const checkAdmin = require('../middleware/checkAdmin'); // Le nouveau middleware admin
const { protect } = require('../middleware/authMiddleware');
// Route pour changer le rôle d'un utilisateur (nécessite d'être authentifié ET admin)
router.patch('/users/:id/role', protect, checkAdmin, (req, res, next) => {
  const userId = req.params.id;
  const newRole = req.body.role; // Le nouveau rôle envoyé dans le corps de la requête

  // Optionnel : Valider que le nouveau rôle est valide (ex: 'user', 'admin')
  if (!['user', 'admin'].includes(newRole)) {
    return res.status(400).json({ message: 'Rôle invalide.' });
  }

  User.updateOne({ _id: userId }, { $set: { role: newRole } })
    .then(result => {
      if (result.matchedCount > 0) { // Utilisez matchedCount ou nModified selon votre version de Mongoose
        res.status(200).json({ message: 'Rôle utilisateur mis à jour avec succès !' });
      } else {
        res.status(404).json({ message: 'Utilisateur non trouvé.' });
      }
    })
    .catch(error => {
      res.status(500).json({ message: 'La mise à jour du rôle a échoué !' });
    });
});

module.exports = router;