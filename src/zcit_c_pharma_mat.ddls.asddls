@EndUserText.label: 'Projection: Pharma Material (Parent)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Search.searchable: true
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true   /* <--- ADD THIS LINE */

define root view entity ZCIT_C_PHARMA_MAT 
  provider contract transactional_query
  as projection on ZCIT_I_PHARMA_MAT
{
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Material ID'
  key MaterialId,
  
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @EndUserText.label: 'Drug Name'
      DrugName,
      
      @EndUserText.label: 'Active Ingredient'
      ActiveIngredient,
      
      @EndUserText.label: 'Drug Category'
      DrugCategory,
      
      @EndUserText.label: 'Shelf Life (Days)'
      ShelfLifeDays,
      
      /* Admin Fields */
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      
      /* CRITICAL LINK: Point the composition to the Child Projection View */
      _Batches : redirected to composition child ZCIT_C_PHARMA_BAT
}
