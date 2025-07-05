const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
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
  logoUrl: {
    type: String,
    default: '',
  },
  imageUrl: {
    type: String,
    default: '',
  },
  // --- NOUVEAU CHAMP POUR L'ORDRE DE TRI ---
  sortOrder: {
    type: Number,
    required: true, // Le champ est obligatoire
    unique: true,   // Chaque valeur de tri doit être unique
    default: 999,   // Une valeur par défaut élevée pour les nouveaux ajouts non spécifiés
  },
});

module.exports = mongoose.model('Order', orderSchema);