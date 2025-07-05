// backend/routes/figurineRoutes.js
const express = require('express');
const {
  addFigurine,
  getMyFigurines,
  getFigurineById,
  updateFigurine,
  deleteFigurine,
  bulkImportFigurines,
  getAllFigurineDefinitions, // Import de la nouvelle fonction pour les définitions
  getAllUserFigurines // Import de la fonction renommée pour toutes les possessions des utilisateurs
} = require('../controllers/figurineController');
const { protect, authorizeRoles } = require('../middleware/authMiddleware'); // Importe protect ET authorizeRoles

const router = express.Router();

// Route POST pour ajouter une figurine (et/ou sa définition/possession)
// Seuls les administrateurs peuvent ajouter de nouvelles définitions ou créer les premières entrées de possession.
router.route('/')
  .post(protect, authorizeRoles('admin'), addFigurine)
  // Route GET pour obtenir toutes les figurines (possessions) de l'utilisateur connecté.
  // Accessible aux 'user' et 'admin' qui sont authentifiés.
  .get(protect, getMyFigurines);

// Routes pour une figurine (possession) spécifique par son ID
router.route('/:id')
  // Route GET pour obtenir une figurine (possession) spécifique.
  // Accessible aux 'user' qui en sont propriétaires, ou aux 'admin'. La logique est dans le contrôleur.
  .get(protect, getFigurineById)
  // Route PUT pour mettre à jour une figurine (possession).
  // Accessible aux 'user' (pour les quantités) et 'admin' (pour tout). La logique est dans le contrôleur.
  .put(protect, authorizeRoles('user', 'admin'), updateFigurine)
  // Route DELETE pour supprimer une figurine (possession).
  // Seuls les administrateurs peuvent supprimer des possessions de n'importe quel utilisateur.
  .delete(protect, authorizeRoles('admin'), deleteFigurine);

// Route POST pour l'importation en masse de figurines (crée/met à jour des possessions).
// Seuls les administrateurs peuvent importer en masse.
router.post('/bulk-import', protect, authorizeRoles('admin'), bulkImportFigurines);

// NOUVELLE ROUTE : Obtenir toutes les DEFINITIONS de figurines (le catalogue global des figurines disponibles).
// Cette route est rendue publique pour permettre l'accès au catalogue sans authentification.
// Si vous souhaitez la protéger, ajoutez 'protect' avant 'getAllFigurineDefinitions'.
router.get('/definitions/all', getAllFigurineDefinitions);

// ROUTE MISE À JOUR : Obtenir toutes les figurines (possessions) de TOUS les utilisateurs.
// Anciennement '/admin/all', maintenant '/admin/all-possessions' pour plus de clarté.
// Réservée aux administrateurs.
router.get('/admin/all-possessions', protect, authorizeRoles('admin'), getAllUserFigurines);

module.exports = router;
