const mongoose = require('mongoose');

const factionSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  description: {
    type: String,
    default: '',
  },
  order: { // Référence à l'Ordre associé (ObjectId)
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order',
    required: true,
  },
  logoUrl: { // Nouveau champ pour le logo de la faction
    type: String,
    default: '',
  },
  imageUrl: { // Nouveau champ pour une image plus grande de la faction
    type: String,
    default: '',
  },
  // --- NOUVEAU CHAMP POUR L'ORDRE DE TRI DES FACTIONS ---
  sortOrder: {
    type: Number,
    required: true, // Le champ est obligatoire
    unique: true,   // Chaque valeur de tri doit être unique
    default: 999,   // Une valeur par défaut élevée pour les nouveaux ajouts non spécifiés
  },
});

module.exports = mongoose.model('Faction', factionSchema);