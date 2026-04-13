@EndUserText.label: 'Value Help: Batch Status'
@ObjectModel.resultSet.sizeCategory: #XS
@Metadata.ignorePropagatedAnnotations: true   /* <--- ADD THIS LINE */
define view entity ZCIT_I_PHARMA_STAT_VH 
  as select from I_Language 
{
  key 'Quarantine' as BatchStatus,
      'Awaiting Lab Testing' as Description
} where Language = 'E'

union all

select from I_Language 
{
  key 'Released' as BatchStatus,
      'Approved for Sale' as Description
} where Language = 'E'

union all

select from I_Language 
{
  key 'Rejected' as BatchStatus,
      'Failed Quality Checks' as Description
} where Language = 'E'
