@EndUserText.label: 'Projection: Pharma Batch (Child)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Search.searchable: true
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true   /* <--- ADD THIS LINE */

define view entity ZCIT_C_PHARMA_BAT 
  as projection on ZCIT_I_PHARMA_BAT
{
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Material ID'
  key MaterialId,
  
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Batch ID'
  key BatchId,
  
      @EndUserText.label: 'Manufacturing Date'
      ManufacturingDate,
      
      @EndUserText.label: 'Expiry Date'
      ExpiryDate,
/* Link the Status Drop-Down */
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCIT_I_PHARMA_STAT_VH', element: 'BatchStatus' } }]
      @EndUserText.label: 'Batch Status'
      BatchStatus,
      
      StatusCriticality,
      
      @EndUserText.label: 'Production Plant'
      ProductionPlant,
      
      @EndUserText.label: 'Quantity'
      Quantity,
      
      /* Link the UoM Drop-Down */
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCIT_I_PHARMA_UOM_VH', element: 'UnitOfMeasure' } }]
      @EndUserText.label: 'Unit of Measure'
      UnitOfMeasure,
      
      /* Admin Fields */
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      
      /* CRITICAL LINK: Point the association back to the Parent Projection View */
      _Drug : redirected to parent ZCIT_C_PHARMA_MAT
}
