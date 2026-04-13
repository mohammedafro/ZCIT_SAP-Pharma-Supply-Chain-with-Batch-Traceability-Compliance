@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View: Pharma Material (Parent)'
@Metadata.ignorePropagatedAnnotations: true   /* <--- ADD THIS LINE */
define root view entity ZCIT_I_PHARMA_MAT 
  as select from zcit_pharma_mat
  
  /* THE MAGIC LINK: This Parent owns 0 to many Batches */
  composition [0..*] of ZCIT_I_PHARMA_BAT as _Batches
{
  key material_id           as MaterialId,
  
      drug_name             as DrugName,
      active_ingredient     as ActiveIngredient,
      drug_category         as DrugCategory,
      shelf_life_days       as ShelfLifeDays,
      
      /* Standard Admin Fields */
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      
      /* You MUST expose the composition here so the framework sees it */
      _Batches
}
