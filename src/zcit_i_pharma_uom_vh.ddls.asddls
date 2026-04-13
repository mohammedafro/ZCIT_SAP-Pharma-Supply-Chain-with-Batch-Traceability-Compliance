@EndUserText.label: 'Value Help: Unit of Measure'
@ObjectModel.resultSet.sizeCategory: #XS
@Metadata.ignorePropagatedAnnotations: true   /* <--- ADD THIS LINE */
define view entity ZCIT_I_PHARMA_UOM_VH 
  as select from I_Language 
{
  key 'BTL' as UnitOfMeasure,
      'Bottles' as Description
} where Language = 'E'

union all

select from I_Language 
{
  key 'TAB' as UnitOfMeasure,
      'Tablets' as Description
} where Language = 'E'

union all

select from I_Language 
{
  key 'BOX' as UnitOfMeasure,
      'Boxes' as Description
} where Language = 'E'
