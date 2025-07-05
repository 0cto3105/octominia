// backend/controllers/figurineController.js
const Figurine = require("../models/Figurine"); // Maintenant, ce modèle représente la "possession" d'une figurine
const FigurineDefinition = require("../models/FigurineDefinition"); // Le nouveau modèle pour la "définition" de la figurine
const Faction = require("../models/Faction"); // Toujours nécessaire pour valider les IDs de faction
const FigurineType = require("../models/FigurineType"); // Toujours nécessaire pour valider les IDs de type

// @desc      Ajouter une nouvelle figurine (une "possession" pour un utilisateur)
//            Ou, si la définition n'existe pas, créer la définition et la possession.
// @route     POST /api/figurines
// @access    Private (Admin seulement via la route `/api/figurines`, car c'est là qu'on ajoute des définitions ou les premières possessions)
//            Pour un user, on modifiera les quantités via PUT ou une route spécifique.
const addFigurine = async (req, res) => {
  // Les données reçues peuvent contenir des informations pour la définition et/ou la possession
  const {
    name,
    faction,
    type,
    imageUrl,
    description,
    onSprue,
    assembled,
    painted,
    needed,
  } = req.body;
  const userId = req.user._id; // L'ID de l'utilisateur authentifié
  const userRole = req.user.role; // Le rôle de l'utilisateur authentifié

  try {
    // Un utilisateur standard ne devrait pas pouvoir créer de nouvelles définitions.
    // Cette route est censée être utilisée par les admins pour ajouter des définitions OU des premières possessions.
    if (userRole !== "admin") {
      return res
        .status(403)
        .json({
          message:
            "Seuls les administrateurs peuvent ajouter de nouvelles définitions de figurines ou créer les premières entrées de possession.",
        });
    }

    // 1. Vérifier si la définition de figurine existe déjà
    let figurineDef = await FigurineDefinition.findOne({ name });

    if (!figurineDef) {
      // Si la définition n'existe pas, il faut la créer (seul un admin peut le faire ici)
      const existingFaction = await Faction.findById(faction);
      const existingType = await FigurineType.findById(type);

      if (!existingFaction) {
        return res
          .status(400)
          .json({
            message: "Faction invalide ou non trouvée pour la définition.",
          });
      }
      if (!existingType) {
        return res
          .status(400)
          .json({
            message:
              "Type de figurine invalide ou non trouvé pour la définition.",
          });
      }

      figurineDef = await FigurineDefinition.create({
        name,
        description: description || `Figurine ${name}.`,
        faction,
        type,
        imageUrl,
      });
      console.log(`Nouvelle définition de figurine créée: ${figurineDef.name}`);
    } else {
      console.log(
        `Définition de figurine existante trouvée: ${figurineDef.name}.`
      );
      // Optionnel: Mettre à jour la définition si l'admin a fourni de nouvelles infos pour une existante
      // Cela peut être géré par une route PUT distincte pour FigurineDefinition si nécessaire.
      // Pour l'instant, cette route ne crée une définition que si elle n'existe pas.
    }

    // 2. Vérifier si l'utilisateur possède déjà une entrée pour cette figurineDefinition
    let userFigurine = await Figurine.findOne({
      figurineDefinition: figurineDef._id,
      user: userId,
    });

    if (userFigurine) {
      // Si l'utilisateur possède déjà cette figurine, on met à jour ses quantités
      // (Cela évite l'erreur d'index unique "figurineDefinition + user")
      userFigurine.onSprue =
        onSprue !== undefined ? onSprue : userFigurine.onSprue;
      userFigurine.assembled =
        assembled !== undefined ? assembled : userFigurine.assembled;
      userFigurine.painted =
        painted !== undefined ? painted : userFigurine.painted;
      userFigurine.needed = needed !== undefined ? needed : userFigurine.needed;
      await userFigurine.save();
      console.log(
        `Quantités mises à jour pour la possession existante de ${figurineDef.name} par ${req.user.username}.`
      );
    } else {
      // Si l'utilisateur ne possède pas encore cette figurine, créer une nouvelle entrée de possession
      userFigurine = await Figurine.create({
        figurineDefinition: figurineDef._id,
        onSprue: onSprue !== undefined ? onSprue : 0,
        assembled: assembled !== undefined ? assembled : 0,
        painted: painted !== undefined ? painted : 0,
        needed: needed !== undefined ? needed : 0,
        user: userId,
      });
      console.log(
        `Nouvelle possession de ${figurineDef.name} créée pour ${req.user.username}.`
      );
    }

    // 3. Populer et renvoyer la possession de figurine
    const populatedUserFigurine = await Figurine.findById(userFigurine._id)
      .populate({
        path: "figurineDefinition",
        populate: [
          {
            path: "faction",
            select: "name imageUrl order sortOrder",
            populate: { path: "order", select: "name logoUrl sortOrder" },
          },
          {
            path: "type",
            select: "name",
          },
        ],
      })
      .populate("user", "username email"); // Popule l'utilisateur propriétaire

    res.status(201).json(populatedUserFigurine);
  } catch (error) {
    console.error("Erreur lors de l'ajout/mise à jour de la figurine:", error);
    if (error.name === "ValidationError") {
      const messages = Object.values(error.errors).map((val) => val.message);
      return res.status(400).json({ message: messages.join(", ") });
    }
    // Gérer spécifiquement l'erreur de doublon pour figurineDefinition name si cela se produit (bien que findOne le gère)
    if (error.code === 11000) {
      return res
        .status(409)
        .json({
          message:
            "Une figurine avec ce nom de définition existe déjà ou vous possédez déjà cette figurine.",
        });
    }
    res
      .status(500)
      .json({
        message:
          "Erreur serveur lors de l'ajout ou de la mise à jour de la figurine.",
      });
  }
};

// @desc      Obtenir toutes les figurines (possessions) de l'utilisateur connecté
// @route     GET /api/figurines
// @access    Private (User et Admin)
const getMyFigurines = async (req, res) => {
  try {
    const figurines = await Figurine.find({ user: req.user._id })
      .populate({
        path: "figurineDefinition",
        populate: [
          {
            path: "faction",
            select: "name imageUrl order sortOrder",
            populate: { path: "order", select: "name logoUrl sortOrder" },
          },
          {
            path: "type",
            select: "name",
          },
        ],
      })
      .sort({ "figurineDefinition.name": 1 }); // Tri sur le nom de la DEFINITION de figurine

    res.json(figurines);
  } catch (error) {
    console.error(
      "Erreur lors de la récupération des figurines de l'utilisateur:",
      error
    );
    res
      .status(500)
      .json({
        message: "Erreur serveur lors de la récupération des figurines.",
      });
  }
};

// @desc      Obtenir une figurine (possession) par son ID de possession
// @route     GET /api/figurines/:id
// @access    Private (User et Admin)
const getFigurineById = async (req, res) => {
  try {
    const figurine = await Figurine.findById(req.params.id)
      .populate({
        path: "figurineDefinition",
        populate: [
          {
            path: "faction",
            select: "name imageUrl order",
            populate: { path: "order", select: "name logoUrl" },
          },
          {
            path: "type",
            select: "name",
          },
        ],
      })
      .populate("user", "username email"); // Popule l'utilisateur propriétaire

    if (!figurine) {
      return res.status(404).json({ message: "Figurine non trouvée." });
    }

    // Un admin peut voir N'IMPORTE QUELLE possession de figurine
    // Un utilisateur standard ne peut voir que SES possessions de figurines
    if (
      req.user.role !== "admin" &&
      figurine.user.toString() !== req.user._id.toString()
    ) {
      return res
        .status(401)
        .json({ message: "Non autorisé à accéder à cette figurine." });
    }

    res.json(figurine);
  } catch (error) {
    console.error(
      "Erreur lors de la récupération de la figurine par ID:",
      error
    );
    res
      .status(500)
      .json({
        message: "Erreur serveur lors de la récupération de la figurine.",
      });
  }
};

// @desc      Mettre à jour une figurine (possession ou définition si admin)
// @route     PUT /api/figurines/:id
// @access    Private (User ou Admin)
const updateFigurine = async (req, res) => {
  // Ces champs concernent la DEFINITION (seul l'admin peut les modifier)
  const { name, faction, type, imageUrl, description } = req.body;
  // Ces champs concernent la POSSESSION (user et admin peuvent les modifier)
  const { onSprue, assembled, painted, needed } = req.body;

  const userRole = req.user.role; // Récupère le rôle de l'utilisateur authentifié
  const figurineId = req.params.id; // C'est l'ID de la possession (Figurine)

  try {
    const figurinePossession = await Figurine.findById(figurineId);

    if (!figurinePossession) {
      return res
        .status(404)
        .json({ message: "Entrée de possession de figurine non trouvée." });
    }

    // Vérification de la propriété : Seul le propriétaire ou un admin peut modifier cette possession.
    if (
      figurinePossession.user.toString() !== req.user._id.toString() &&
      userRole !== "admin"
    ) {
      return res
        .status(401)
        .json({
          message:
            "Non autorisé à modifier cette entrée de possession (vous n'êtes pas le propriétaire et n'êtes pas administrateur).",
        });
    }

    // LOGIQUE DE MISE À JOUR BASÉE SUR LES RÔLES
    if (userRole === "user") {
      // Un utilisateur normal ne peut modifier que les champs de stock sur sa possession
      const allowedPossessionFields = [
        "onSprue",
        "assembled",
        "painted",
        "needed",
      ]; // Ajout de 'needed'
      const receivedFields = Object.keys(req.body);

      // Vérifier si des champs non autorisés (de la définition par exemple) sont présents
      const unauthorizedFields = receivedFields.filter(
        (field) => !allowedPossessionFields.includes(field)
      );

      if (unauthorizedFields.length > 0) {
        return res.status(403).json({
          message: `Vous n'êtes pas autorisé à modifier les champs suivants : ${unauthorizedFields.join(
            ", "
          )}. Seuls les champs de quantité ('onSprue', 'assembled', 'painted', 'needed') peuvent être modifiés.`,
        });
      }

      // Appliquer les modifications autorisées sur la possession
      if (onSprue !== undefined) figurinePossession.onSprue = onSprue;
      if (assembled !== undefined) figurinePossession.assembled = assembled;
      if (painted !== undefined) figurinePossession.painted = painted;
      if (needed !== undefined) figurinePossession.needed = needed;
    } else if (userRole === "admin") {
      // Un administrateur peut modifier tous les champs de la possession
      // ET potentiellement la définition de la figurine associée.

      // Mise à jour des champs de possession
      if (onSprue !== undefined) figurinePossession.onSprue = onSprue;
      if (assembled !== undefined) figurinePossession.assembled = assembled;
      if (painted !== undefined) figurinePossession.painted = painted;
      if (needed !== undefined) figurinePossession.needed = needed;

      // Mise à jour de la DEFINITION de figurine si des champs pertinents sont fournis
      const figurineDef = await FigurineDefinition.findById(
        figurinePossession.figurineDefinition
      );
      if (!figurineDef) {
        // Cela ne devrait pas arriver si la DB est cohérente, mais pour la robustesse
        return res
          .status(500)
          .json({ message: "Définition de figurine associée introuvable." });
      }

      let defUpdated = false;
      if (name !== undefined) {
        figurineDef.name = name;
        defUpdated = true;
      }
      if (description !== undefined) {
        figurineDef.description = description;
        defUpdated = true;
      }
      if (imageUrl !== undefined) {
        figurineDef.imageUrl = imageUrl;
        defUpdated = true;
      }

      // Valider et mettre à jour les IDs de faction et de type si l'admin les modifie
      if (faction !== undefined && faction !== null) {
        const existingFaction = await Faction.findById(faction);
        if (!existingFaction) {
          return res
            .status(400)
            .json({
              message:
                "Faction invalide ou non trouvée lors de la mise à jour de la définition.",
            });
        }
        figurineDef.faction = faction;
        defUpdated = true;
      }
      if (type !== undefined && type !== null) {
        const existingType = await FigurineType.findById(type);
        if (!existingType) {
          return res
            .status(400)
            .json({
              message:
                "Type de figurine invalide ou non trouvé lors de la mise à jour de la définition.",
            });
        }
        figurineDef.type = type;
        defUpdated = true;
      }

      if (defUpdated) {
        await figurineDef.save();
        console.log(
          `Définition de figurine (${figurineDef.name}) mise à jour par l'admin.`
        );
      }
    } else {
      return res
        .status(403)
        .json({
          message: "Votre rôle ne vous permet pas de modifier cette figurine.",
        });
    }

    const updatedFigurinePossession = await figurinePossession.save();

    // Populer la possession mise à jour pour la réponse
    const populatedFigurine = await Figurine.findById(
      updatedFigurinePossession._id
    )
      .populate({
        path: "figurineDefinition",
        populate: [
          {
            path: "faction",
            select: "name imageUrl order",
            populate: { path: "order", select: "name logoUrl" },
          },
          {
            path: "type",
            select: "name",
          },
        ],
      })
      .populate("user", "username email");

    res.json(populatedFigurine);
  } catch (error) {
    console.error("Erreur lors de la mise à jour de la figurine:", error);
    if (error.name === "ValidationError") {
      const messages = Object.values(error.errors).map((val) => val.message);
      return res.status(400).json({ message: messages.join(", ") });
    }
    if (error.code === 11000) {
      // Doublon sur le nom de la définition si admin modifie un nom existant
      return res
        .status(409)
        .json({
          message:
            "Le nom de la figurine de définition est déjà utilisé par une autre définition.",
        });
    }
    res
      .status(500)
      .json({
        message: "Erreur serveur lors de la mise à jour de la figurine.",
      });
  }
};

// @desc      Supprimer une figurine (possession)
// @route     DELETE /api/figurines/:id
// @access    Private (Admin seulement via la route)
const deleteFigurine = async (req, res) => {
  try {
    const figurine = await Figurine.findById(req.params.id);

    if (!figurine) {
      return res
        .status(404)
        .json({ message: "Entrée de possession de figurine non trouvée." });
    }

    // Le middleware authorizeRoles('admin') sur la route garantit que seul un admin accède ici.
    // Un admin peut supprimer n'importe quelle entrée de possession.
    await Figurine.deleteOne({ _id: req.params.id });
    res.json({ message: "Possession de figurine supprimée avec succès." });
  } catch (error) {
    console.error("Erreur lors de la suppression de la figurine:", error);
    res
      .status(500)
      .json({
        message: "Erreur serveur lors de la suppression de la figurine.",
      });
  }
};

// @desc      Importer des figurines en masse (pour créer/mettre à jour des possessions)
// @route     POST /api/figurines/bulk-import
// @access    Private (Admin seulement via la route)
const bulkImportFigurines = async (req, res) => {
  // Le corps de la requête doit être un tableau d'objets contenant :
  // { name: "Nom Figurine", faction: "factionId", type: "typeId", onSprue, assembled, painted, needed, imageUrl? }
  const figurinesToImport = req.body;
  const userId = req.user._id;

  if (!Array.isArray(figurinesToImport) || figurinesToImport.length === 0) {
    return res
      .status(400)
      .json({
        message:
          "Le corps de la requête doit être un tableau non vide de figurines à importer.",
      });
  }

  const importResults = [];

  try {
    // Récupérer toutes les définitions existantes une fois pour toutes
    const allFigurineDefinitions = await FigurineDefinition.find({});
    const figurineDefMapByName = new Map(
      allFigurineDefinitions.map((def) => [def.name, def])
    );

    // Récupérer toutes les factions et types existants pour validation
    const allFactions = await Faction.find({});
    const factionMap = new Map(allFactions.map((f) => [f._id.toString(), f]));
    const allFigurineTypes = await FigurineType.find({});
    const typeMap = new Map(allFigurineTypes.map((t) => [t._id.toString(), t]));

    for (const figData of figurinesToImport) {
      const {
        name,
        faction,
        type,
        imageUrl,
        description,
        onSprue,
        assembled,
        painted,
        needed,
      } = figData;
      let currentFigurineDef = figurineDefMapByName.get(name);

      try {
        // --- Créer/Récupérer la FigurineDefinition ---
        if (!currentFigurineDef) {
          // Si la définition n'existe pas, la créer (uniquement si toutes les refs sont valides)
          const existingFaction = factionMap.get(faction);
          const existingType = typeMap.get(type);

          if (!existingFaction) {
            importResults.push({
              status: "failed",
              name: name,
              reason: `Faction invalide ou non trouvée pour l'ID: ${faction}`,
            });
            continue;
          }
          if (!existingType) {
            importResults.push({
              status: "failed",
              name: name,
              reason: `Type de figurine invalide ou non trouvé pour l'ID: ${type}`,
            });
            continue;
          }

          currentFigurineDef = await FigurineDefinition.create({
            name,
            description: description || `Définition de la figurine ${name}.`,
            faction,
            type,
            imageUrl,
          });
          figurineDefMapByName.set(name, currentFigurineDef); // Ajout à la map pour les futures itérations
        }

        // --- Créer/Mettre à jour la Possession de Figurine pour l'utilisateur ---
        let userFigurine = await Figurine.findOne({
          figurineDefinition: currentFigurineDef._id,
          user: userId,
        });

        if (userFigurine) {
          // Mettre à jour les quantités si l'entrée existe
          userFigurine.onSprue =
            onSprue !== undefined ? onSprue : userFigurine.onSprue;
          userFigurine.assembled =
            assembled !== undefined ? assembled : userFigurine.assembled;
          userFigurine.painted =
            painted !== undefined ? painted : userFigurine.painted;
          userFigurine.needed =
            needed !== undefined ? needed : userFigurine.needed;
          await userFigurine.save();
          importResults.push({
            status: "updated",
            name: name,
            id: userFigurine._id,
          });
        } else {
          // Créer une nouvelle entrée de possession
          const newPossession = await Figurine.create({
            figurineDefinition: currentFigurineDef._id,
            onSprue: onSprue !== undefined ? onSprue : 0,
            assembled: assembled !== undefined ? assembled : 0,
            painted: painted !== undefined ? painted : 0,
            needed: needed !== undefined ? needed : 0,
            user: userId,
          });
          importResults.push({
            status: "success",
            name: name,
            id: newPossession._id,
          });
        }
      } catch (validationError) {
        console.error(
          `Erreur de validation pour la figurine ${name || "sans nom"} :`,
          validationError.message
        );
        let reason =
          validationError.message ||
          "Erreur de validation lors de l'enregistrement.";
        if (validationError.code === 11000) {
          reason =
            "Doublon : Une définition de figurine avec ce nom existe déjà, ou vous possédez déjà cette figurine.";
        }
        importResults.push({
          status: "failed",
          name: name || "Sans nom",
          reason: reason,
        });
      }
    }

    const successes = importResults.filter(
      (r) => r.status === "success"
    ).length;
    const updates = importResults.filter((r) => r.status === "updated").length;
    const failures = importResults.filter((r) => r.status === "failed").length;

    if (failures > 0) {
      return res.status(207).json({
        message: `Importation terminée : ${successes} figurines insérées, ${updates} mises à jour, ${failures} échecs.`,
        results: importResults,
      });
    } else {
      return res.status(201).json({
        message: `${
          successes + updates
        } figurines importées/mises à jour avec succès !`,
        results: importResults,
      });
    }
  } catch (error) {
    console.error("Erreur serveur lors de l'importation en masse :", error);
    res
      .status(500)
      .json({
        message: "Erreur serveur lors de l'importation en masse.",
        error: error.message,
      });
  }
};

// @desc      Obtenir toutes les définitions de figurines (pour tous les utilisateurs)
// @route     GET /api/figurines/definitions/all
// @access    Public (ou Private si vous le souhaitez)
//            Cette route renvoie toutes les fiches techniques des figurines, pas les possessions.
const getAllFigurineDefinitions = async (req, res) => {
  try {
    // Popule la faction et le type pour chaque définition
    const figurineDefinitions = await FigurineDefinition.find({})
      .populate({
        path: "faction",
        select: "name imageUrl order sortOrder",
        populate: { path: "order", select: "name logoUrl sortOrder" },
      })
      .populate("type", "name")
      .sort({ name: 1 }); // Tri par nom de définition

    res.json(figurineDefinitions);
  } catch (error) {
    console.error(
      "Erreur lors de la récupération de toutes les définitions de figurines:",
      error
    );
    res
      .status(500)
      .json({
        message:
          "Erreur serveur lors de la récupération des définitions de figurines.",
        error: error.message,
      });
  }
};

// Ancienne fonction getAllFigurines pour admin (qui retournait les possessions de tous les users)
// @desc      Obtenir toutes les figurines (possessions) de TOUS les utilisateurs (Admin seulement)
// @route     GET /api/figurines/admin/all
// @access    Private (Admin seulement via la route)
const getAllUserFigurines = async (req, res) => {
  try {
    const figurines = await Figurine.find({}) // Pas de filtre par utilisateur ici
      .populate({
        path: "figurineDefinition",
        populate: [
          {
            path: "faction",
            select: "name imageUrl order sortOrder",
            populate: { path: "order", select: "name logoUrl sortOrder" },
          },
          {
            path: "type",
            select: "name",
          },
        ],
      })
      .populate("user", "username email") // Popule l'utilisateur propriétaire
      .sort({ "figurineDefinition.name": 1 }); // Tri par nom de la définition

    res.json(figurines);
  } catch (error) {
    console.error(
      "Erreur lors de la récupération de toutes les figurines (admin):",
      error
    );
    res
      .status(500)
      .json({
        message:
          "Erreur serveur lors de la récupération de toutes les figurines.",
      });
  }
};

module.exports = {
  addFigurine,
  getMyFigurines,
  getFigurineById,
  updateFigurine,
  deleteFigurine,
  bulkImportFigurines,
  getAllFigurineDefinitions, // Nouvelle fonction exportée
  getAllUserFigurines, // Renommé et exporté
};
