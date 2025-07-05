const express = require('express');
const router = express.Router();
const Faction = require('../models/Faction');
const { protect, authorizeRoles } = require('../middleware/authMiddleware'); // Importe protect ET authorizeRoles

// GET toutes les factions (avec population de l'ordre si référence)
// Tri par 'sortOrder' croissant pour respecter l'ordre défini
router.get('/', async (req, res) => {
  try {
    // MODIFICATION ICI : Tri par 'sortOrder' au lieu de 'name'
    // Vous pouvez également ajouter un tri secondaire par 'name' si des factions ont le même sortOrder
    const factions = await Faction.find().populate('order').sort({ sortOrder: 1, name: 1 });
    res.status(200).json(factions);
  } catch (error) {
    console.error("Erreur lors de la récupération des factions:", error); // Ajout d'un console.error pour le débogage
    res.status(500).json({ message: 'Erreur lors de la récupération des factions.', error });
  }
});

// POST une nouvelle faction
// Accessible uniquement aux administrateurs
router.post('/', protect, authorizeRoles('admin'), async (req, res) => { // Ajout de authorizeRoles('admin')
  // MODIFICATION ICI : Inclure 'sortOrder' dans la décomposition et le constructeur
  const { name, description, order, imageUrl, logoUrl, sortOrder } = req.body;
  const newFaction = new Faction({ name, description, order, imageUrl, logoUrl, sortOrder });
  
  try {
    const savedFaction = await newFaction.save();
    await savedFaction.populate('order'); // Popule l'ordre après sauvegarde pour la réponse
    res.status(201).json(savedFaction);
  } catch (error) {
    if (error.code === 11000) { // Erreur de duplicata MongoDB (pour name ou sortOrder si unique)
      let message = 'Une faction avec ce nom existe déjà.';
      // Si l'erreur est due à sortOrder unique
      if (error.keyPattern && error.keyPattern.sortOrder) {
          message = 'Une valeur de tri (sortOrder) existe déjà pour une autre faction.';
      }
      return res.status(409).json({ message: message });
    }
    console.error("Erreur lors de la création de la faction:", error); // Ajout d'un console.error pour le débogage
    res.status(400).json({ message: 'Erreur lors de la création de la faction.', error });
  }
});

// --- Suggestions pour d'autres routes (similaire à ce que nous avons fait pour les ordres) ---

// // PUT (update) une faction existante (protégé, admin seulement)
// router.put('/:id', protect, authorizeRoles('admin'), async (req, res) => {
//   const { name, description, order, imageUrl, logoUrl, sortOrder } = req.body;
//   try {
//     const updatedFaction = await Faction.findByIdAndUpdate(
//       req.params.id,
//       { name, description, order, imageUrl, logoUrl, sortOrder },
//       { new: true, runValidators: true }
//     );
//     if (!updatedFaction) {
//       return res.status(404).json({ message: 'Faction non trouvée.' });
//     }
//     await updatedFaction.populate('order');
//     res.status(200).json(updatedFaction);
//   } catch (error) {
//     if (error.code === 11000) {
//       return res.status(409).json({ message: 'Une faction avec ce nom ou cette valeur de tri existe déjà.' });
//     }
//     res.status(400).json({ message: 'Erreur lors de la mise à jour de la faction.', error });
//   }
// });

// // DELETE une faction (protégé, admin seulement)
// router.delete('/:id', protect, authorizeRoles('admin'), async (req, res) => {
//   try {
//     const deletedFaction = await Faction.findByIdAndDelete(req.params.id);
//     if (!deletedFaction) {
//       return res.status(404).json({ message: 'Faction non trouvée.' });
//     }
//     res.status(200).json({ message: 'Faction supprimée avec succès.' });
//   } catch (error) {
//     res.status(500).json({ message: 'Erreur lors de la suppression de la faction.', error });
//   }
// });

// // GET une faction par ID
// router.get('/:id', async (req, res) => {
//   try {
//     const faction = await Faction.findById(req.params.id).populate('order');
//     if (!faction) {
//       return res.status(404).json({ message: 'Faction non trouvée.' });
//     }
//     res.status(200).json(faction);
//   } catch (error) {
//     res.status(500).json({ message: 'Erreur lors de la récupération de la faction par ID.', error });
//   }
// });


module.exports = router;