const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const { protect, authorizeRoles } = require('../middleware/authMiddleware'); // Importe protect ET authorizeRoles

// GET toutes les ordres
// Tri par 'sortOrder' croissant pour respecter l'ordre défini
router.get('/', async (req, res) => {
  try {
    // MODIFICATION ICI : Tri par 'sortOrder' au lieu de 'name'
    const orders = await Order.find().sort({ sortOrder: 1 }); // Tri ascendant par sortOrder
    res.status(200).json(orders);
  } catch (error) {
    console.error("Erreur lors de la récupération des ordres:", error); // Ajout d'un console.error pour le débogage
    res.status(500).json({ message: 'Erreur lors de la récupération des ordres.', error });
  }
});

// POST un nouvel ordre
// Accessible uniquement aux administrateurs
router.post('/', protect, authorizeRoles('admin'), async (req, res) => { // Ajout de authorizeRoles('admin')
  // MODIFICATION ICI : Inclure 'sortOrder' dans la décomposition et le constructeur
  const { name, description, logoUrl, imageUrl, sortOrder } = req.body;
  const newOrder = new Order({ name, description, logoUrl, imageUrl, sortOrder });
  
  try {
    const savedOrder = await newOrder.save();
    res.status(201).json(savedOrder);
  } catch (error) {
    if (error.code === 11000) { // Erreur de duplicata MongoDB (pour name ou sortOrder si unique)
      let message = 'Un ordre avec ce nom existe déjà.';
      // Si l'erreur est due à sortOrder unique
      if (error.keyPattern && error.keyPattern.sortOrder) {
          message = 'Une valeur de tri (sortOrder) existe déjà pour un autre ordre.';
      }
      return res.status(409).json({ message: message });
    }
    console.error("Erreur lors de la création de l'ordre:", error); // Ajout d'un console.error pour le débogage
    res.status(400).json({ message: 'Erreur lors de la création de l\'ordre.', error });
  }
});

// --- Suggestions pour d'autres routes (à implémenter dans un fichier de contrôleur dédié si l'API grossit) ---

// // PUT (update) un ordre existant (protégé, admin seulement)
// router.put('/:id', protect, authorizeRoles('admin'), async (req, res) => {
//   const { name, description, logoUrl, imageUrl, sortOrder } = req.body;
//   try {
//     const updatedOrder = await Order.findByIdAndUpdate(
//       req.params.id,
//       { name, description, logoUrl, imageUrl, sortOrder },
//       { new: true, runValidators: true } // Retourne le document modifié, et applique les validations du schéma
//     );
//     if (!updatedOrder) {
//       return res.status(404).json({ message: 'Ordre non trouvé.' });
//     }
//     res.status(200).json(updatedOrder);
//   } catch (error) {
//     if (error.code === 11000) {
//       return res.status(409).json({ message: 'Un ordre avec ce nom ou cette valeur de tri existe déjà.' });
//     }
//     res.status(400).json({ message: 'Erreur lors de la mise à jour de l\'ordre.', error });
//   }
// });

// // DELETE un ordre (protégé, admin seulement)
// router.delete('/:id', protect, authorizeRoles('admin'), async (req, res) => {
//   try {
//     const deletedOrder = await Order.findByIdAndDelete(req.params.id);
//     if (!deletedOrder) {
//       return res.status(404).json({ message: 'Ordre non trouvé.' });
//     }
//     res.status(200).json({ message: 'Ordre supprimé avec succès.' });
//   } catch (error) {
//     res.status(500).json({ message: 'Erreur lors de la suppression de l\'ordre.', error });
//   }
// });

// // GET un ordre par ID (protégé si nécessaire, ou public)
// router.get('/:id', async (req, res) => {
//   try {
//     const order = await Order.findById(req.params.id);
//     if (!order) {
//       return res.status(404).json({ message: 'Ordre non trouvé.' });
//     }
//     res.status(200).json(order);
//   } catch (error) {
//     res.status(500).json({ message: 'Erreur lors de la récupération de l\'ordre par ID.', error });
//   }
// });

module.exports = router;