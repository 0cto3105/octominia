// backend/models/FigurineDefinition.js
// Ce modèle définit les caractéristiques génériques et uniques d'une figurine
// (son nom, sa faction, son type, son image), qui sont communes à tous les utilisateurs.

const mongoose = require("mongoose");
const Schema = mongoose.Schema; // Ajout pour faciliter la lecture des références ObjectId

const figurineDefinitionSchema = new Schema({
  name: {
    type: String,
    required: true,
    trim: true,
    unique: true, // Le nom de la figurine (sa définition) doit être UNIQUE dans la base de données
  },
  description: {
    type: String,
    default: '',
  },
  // Référence à la Faction à laquelle cette figurine appartient
  faction: {
    type: Schema.Types.ObjectId,
    ref: "Faction",
    required: true,
  },
  // Référence au Type de Figurine (Infanterie, Héros, Monstre, etc.)
  type: {
    type: Schema.Types.ObjectId,
    ref: "FigurineType",
    required: true,
  },
  // URL de l'image de la figurine (commune à toutes les instances de cette figurine)
  imageUrl: {
    type: String,
    trim: true,
    default: "https://via.placeholder.com/150", // Image par défaut si aucune n'est fournie
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

const FigurineDefinition = mongoose.model("FigurineDefinition", figurineDefinitionSchema);

module.exports = FigurineDefinition;