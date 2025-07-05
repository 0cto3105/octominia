// backend/models/Figurine.js
// Ce modèle représente la "possession" d'une figurine spécifique par un utilisateur.
// Il référence une définition de figurine (FigurineDefinition) et stocke les quantités propres à l'utilisateur.

const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const figurineSchema = new Schema({
  // Supprimé : name, faction, type, imageUrl (ces infos sont maintenant dans FigurineDefinition)
  // Elles seront accessibles via la référence à figurineDefinition

  // AJOUT : Référence à la définition de la figurine
  figurineDefinition: {
    type: Schema.Types.ObjectId,
    ref: "FigurineDefinition", // Référence au NOUVEAU modèle FigurineDefinition
    required: true,
  },

  // Quantités possédées par l'utilisateur (ces champs sont spécifiques à l'utilisateur)
  onSprue: { // Sur grappe
    type: Number,
    required: true,
    default: 0,
    min: 0,
  },
  assembled: { // Montées
    type: Number,
    required: true,
    default: 0,
    min: 0,
  },
  painted: { // Peintes
    type: Number,
    required: true,
    default: 0,
    min: 0,
  },
  needed: { // Nombre dont l'utilisateur a besoin
    type: Number,
    required: true,
    default: 0,
    min: 0,
  },
  // Chaque entrée de possession est liée à un utilisateur
  user: {
    type: Schema.Types.ObjectId, // Référence à l'ID de l'utilisateur propriétaire
    ref: "User", // Fait référence au modèle 'User'
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// IMPORTANT : Ajout d'un index unique composé.
// Cela garantit qu'un même utilisateur ne peut avoir qu'une seule entrée de possession
// pour une définition de figurine donnée.
figurineSchema.index({ figurineDefinition: 1, user: 1 }, { unique: true });


const Figurine = mongoose.model("Figurine", figurineSchema);

module.exports = Figurine;