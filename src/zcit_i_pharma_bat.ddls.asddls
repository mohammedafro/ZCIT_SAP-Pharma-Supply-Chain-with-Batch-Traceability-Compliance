@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View: Pharma Batch (Child)'
@Metadata.ignorePropagatedAnnotations: true   /* <--- ADD THIS LINE */
define view entity ZCIT_I_PHARMA_BAT 
  as select from zcit_pharma_bat
  
  /* THE MAGIC LINK: I am a Child, and I am associated to my Parent */
  association to parent ZCIT_I_PHARMA_MAT as _Drug 
    on $projection.MaterialId = _Drug.MaterialId
{
  key material_id           as MaterialId,
  key batch_id              as BatchId,
  
      manufacturing_date    as ManufacturingDate,
      expiry_date           as ExpiryDate,
      
      batch_status          as BatchStatus,
      /* DYNAMIC COLORS: Compliance Status */
      case batch_status
        when 'Released'   then 3  /* 3 = Green  */
        when 'Quarantine' then 2  /* 2 = Orange */
        when 'Rejected'   then 1  /* 1 = Red    */
        else 0
      end                   as StatusCriticality,
      
      production_plant      as ProductionPlant,
      quantity              as Quantity,
      unit_of_measure       as UnitOfMeasure,
      
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
      
      /* You MUST expose the parent association here */
      _Drug
}
