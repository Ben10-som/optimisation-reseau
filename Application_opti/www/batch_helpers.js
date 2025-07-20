// www/batch_helpers.js
// Script pour améliorer la sélection de fichiers multiples

$(document).ready(function() {
  // Observer le changement du sélecteur de fichiers batch
  var batchInputObserver = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.addedNodes.length) {
        enhanceBatchFileInput();
      }
    });
  });
  
  // Observer tout changement dans le DOM
  batchInputObserver.observe(document.body, { childList: true, subtree: true });
  
  // Appeler immédiatement au cas où l'élément est déjà présent
  enhanceBatchFileInput();
});

// Fonction pour améliorer l'input de sélection de fichiers multiples
function enhanceBatchFileInput() {
  var batchInput = $('input#batch_files');
  
  if (batchInput.length) {
    // S'assurer que l'attribut "multiple" est présent et activé
    if (!batchInput.prop('multiple')) {
      console.log("Activating multiple files support");
      batchInput.prop('multiple', true);
    }
    
    // Ajouter des styles personnalisés
    batchInput.parent().addClass('multi-file-enhanced');
    
    // Désenregistrer l'observateur une fois l'élément trouvé et amélioré
    if (batchInputObserver) {
      batchInputObserver.disconnect();
    }
  }
} 