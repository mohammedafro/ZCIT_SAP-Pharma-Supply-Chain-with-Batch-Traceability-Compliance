" ==============================================================================
" 1. THE DUAL-BUFFER (Holds data before committing to the DB)
" ==============================================================================
CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA: mt_drug_ins TYPE TABLE OF zcit_pharma_mat,
                mt_drug_upd TYPE TABLE OF zcit_pharma_mat,
                mt_drug_del TYPE TABLE OF zcit_pharma_mat.

    CLASS-DATA: mt_batch_ins TYPE TABLE OF zcit_pharma_bat,
                mt_batch_upd TYPE TABLE OF zcit_pharma_bat,
                mt_batch_del TYPE TABLE OF zcit_pharma_bat.
ENDCLASS.

" ==============================================================================
" 2. THE HANDLER DEFINITION
" ==============================================================================
CLASS lhc_Drug DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    " Only the Parent needs instance authorization. The Child relies on this.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Drug RESULT result.

    " Parent Methods
    METHODS create FOR MODIFY IMPORTING entities FOR CREATE Drug.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE Drug.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE Drug.
    METHODS read   FOR READ   IMPORTING keys FOR READ Drug RESULT result.
    METHODS lock   FOR LOCK   IMPORTING keys FOR LOCK Drug.

    " Cross-Entity Methods
    METHODS rba_Batches FOR READ   IMPORTING keys_rba FOR READ Drug\_Batches FULL result_requested RESULT result LINK association_links.
    METHODS cba_Batches FOR MODIFY IMPORTING entities_cba FOR CREATE Drug\_Batches.

    " Child Methods
    METHODS update_batch FOR MODIFY IMPORTING entities FOR UPDATE Batch.
    METHODS delete_batch FOR MODIFY IMPORTING keys     FOR DELETE Batch.
    METHODS read_batch   FOR READ   IMPORTING keys     FOR READ Batch RESULT result.

    " Custom Actions
    METHODS releaseBatch FOR MODIFY IMPORTING keys FOR ACTION Batch~releaseBatch RESULT result.
    METHODS rejectBatch  FOR MODIFY IMPORTING keys FOR ACTION Batch~rejectBatch  RESULT result.
ENDCLASS.

" ==============================================================================
" 3. THE HANDLER IMPLEMENTATION
" ==============================================================================
CLASS lhc_Drug IMPLEMENTATION.

  METHOD get_instance_authorizations.
    " Kept empty to allow free access during testing
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  " --- PARENT METHODS ---
  METHOD create.
    GET TIME STAMP FIELD DATA(lv_now).
    LOOP AT entities INTO DATA(ls_entity).
      APPEND VALUE #( material_id       = ls_entity-MaterialId
                      drug_name         = ls_entity-DrugName
                      active_ingredient = ls_entity-ActiveIngredient
                      drug_category     = ls_entity-DrugCategory
                      shelf_life_days   = ls_entity-ShelfLifeDays
                      created_at        = lv_now ) TO lcl_buffer=>mt_drug_ins.

      INSERT VALUE #( %cid       = ls_entity-%cid
                      MaterialId = ls_entity-MaterialId ) INTO TABLE mapped-drug.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    LOOP AT entities INTO DATA(ls_entity).
      SELECT SINGLE * FROM zcit_pharma_mat WHERE material_id = @ls_entity-MaterialId INTO @DATA(ls_db).
      IF ls_entity-%control-DrugName = if_abap_behv=>mk-on.         ls_db-drug_name = ls_entity-DrugName. ENDIF.
      IF ls_entity-%control-ActiveIngredient = if_abap_behv=>mk-on. ls_db-active_ingredient = ls_entity-ActiveIngredient. ENDIF.
      IF ls_entity-%control-DrugCategory = if_abap_behv=>mk-on.     ls_db-drug_category = ls_entity-DrugCategory. ENDIF.
      IF ls_entity-%control-ShelfLifeDays = if_abap_behv=>mk-on.    ls_db-shelf_life_days = ls_entity-ShelfLifeDays. ENDIF.
      APPEND ls_db TO lcl_buffer=>mt_drug_upd.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #( material_id = ls_key-MaterialId ) TO lcl_buffer=>mt_drug_del.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    SELECT * FROM zcit_pharma_mat FOR ALL ENTRIES IN @keys WHERE material_id = @keys-MaterialId INTO TABLE @DATA(lt_drug).
    result = CORRESPONDING #( lt_drug MAPPING MaterialId = material_id DrugName = drug_name ActiveIngredient = active_ingredient DrugCategory = drug_category ShelfLifeDays = shelf_life_days ).
  ENDMETHOD.

  " --- CHILD METHODS ---
  METHOD cba_Batches.
    GET TIME STAMP FIELD DATA(lv_now).
    DATA(lo_rand) = cl_abap_random_int=>create( min = 1000 max = 9999 ).

    LOOP AT entities_cba INTO DATA(ls_cba).
      SELECT SINGLE shelf_life_days FROM zcit_pharma_mat WHERE material_id = @ls_cba-MaterialId INTO @DATA(lv_shelf_life).
      DATA(lv_new_batch_id) = |BAT-{ lo_rand->get_next( ) }|.

      LOOP AT ls_cba-%target INTO DATA(ls_target).

        " Safe Date Calculation (Prevents crash if UI sends blank date)
        DATA(lv_expiry) = ls_target-ManufacturingDate.
        IF ls_target-ManufacturingDate IS NOT INITIAL.
          lv_expiry = ls_target-ManufacturingDate + lv_shelf_life.
        ENDIF.

        " Default Status
        DATA(lv_status) = ls_target-BatchStatus.
        IF lv_status IS INITIAL. lv_status = 'Quarantine'. ENDIF.

        APPEND VALUE #( material_id        = ls_cba-MaterialId
                        batch_id           = lv_new_batch_id
                        manufacturing_date = ls_target-ManufacturingDate
                        expiry_date        = lv_expiry
                        batch_status       = lv_status
                        production_plant   = ls_target-ProductionPlant
                        quantity           = ls_target-Quantity
                        unit_of_measure    = ls_target-UnitOfMeasure
                        created_at         = lv_now ) TO lcl_buffer=>mt_batch_ins.

        INSERT VALUE #( %cid       = ls_target-%cid
                        MaterialId = ls_cba-MaterialId
                        BatchId    = lv_new_batch_id ) INTO TABLE mapped-batch.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD update_batch.
    LOOP AT entities INTO DATA(ls_entity).
      SELECT SINGLE * FROM zcit_pharma_bat WHERE material_id = @ls_entity-MaterialId AND batch_id = @ls_entity-BatchId INTO @DATA(ls_db).
      IF ls_entity-%control-ManufacturingDate = if_abap_behv=>mk-on. ls_db-manufacturing_date = ls_entity-ManufacturingDate. ENDIF.
      IF ls_entity-%control-ProductionPlant = if_abap_behv=>mk-on.   ls_db-production_plant = ls_entity-ProductionPlant. ENDIF.
      IF ls_entity-%control-Quantity = if_abap_behv=>mk-on.          ls_db-quantity = ls_entity-Quantity. ENDIF.
      IF ls_entity-%control-UnitOfMeasure = if_abap_behv=>mk-on.     ls_db-unit_of_measure = ls_entity-UnitOfMeasure. ENDIF.
      APPEND ls_db TO lcl_buffer=>mt_batch_upd.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete_batch.
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #( material_id = ls_key-MaterialId
                      batch_id    = ls_key-BatchId ) TO lcl_buffer=>mt_batch_del.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_batch.
    SELECT * FROM zcit_pharma_bat FOR ALL ENTRIES IN @keys WHERE material_id = @keys-MaterialId AND batch_id = @keys-BatchId INTO TABLE @DATA(lt_batch).
    result = CORRESPONDING #( lt_batch MAPPING MaterialId = material_id BatchId = batch_id ManufacturingDate = manufacturing_date ExpiryDate = expiry_date BatchStatus = batch_status ProductionPlant = production_plant Quantity = quantity UnitOfMeasure =
unit_of_measure ).
  ENDMETHOD.

  METHOD rba_Batches.
    SELECT * FROM zcit_pharma_bat FOR ALL ENTRIES IN @keys_rba WHERE material_id = @keys_rba-MaterialId INTO TABLE @DATA(lt_batch).
    result = CORRESPONDING #( lt_batch MAPPING MaterialId = material_id BatchId = batch_id ).

    " Strict Association Links
    LOOP AT lt_batch INTO DATA(ls_db).
      INSERT VALUE #( source-MaterialId = ls_db-material_id
                      target-MaterialId = ls_db-material_id
                      target-BatchId    = ls_db-batch_id ) INTO TABLE association_links.
    ENDLOOP.
  ENDMETHOD.

  " --- ACTION METHODS ---
  METHOD releaseBatch.
    LOOP AT keys INTO DATA(ls_key).
      SELECT SINGLE * FROM zcit_pharma_bat WHERE material_id = @ls_key-MaterialId AND batch_id = @ls_key-BatchId INTO @DATA(ls_db).
      ls_db-batch_status = 'Released'.
      APPEND ls_db TO lcl_buffer=>mt_batch_upd.

      INSERT VALUE #( MaterialId = ls_key-MaterialId
                      BatchId    = ls_key-BatchId
                      %param     = VALUE #( MaterialId  = ls_key-MaterialId
                                            BatchId     = ls_key-BatchId
                                            BatchStatus = 'Released' ) ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD rejectBatch.
    LOOP AT keys INTO DATA(ls_key).
      SELECT SINGLE * FROM zcit_pharma_bat WHERE material_id = @ls_key-MaterialId AND batch_id = @ls_key-BatchId INTO @DATA(ls_db).
      ls_db-batch_status = 'Rejected'.
      APPEND ls_db TO lcl_buffer=>mt_batch_upd.

      INSERT VALUE #( MaterialId = ls_key-MaterialId
                      BatchId    = ls_key-BatchId
                      %param     = VALUE #( MaterialId  = ls_key-MaterialId
                                            BatchId     = ls_key-BatchId
                                            BatchStatus = 'Rejected' ) ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

" ==============================================================================
" 4. THE SAVER CLASS (Commits buffer to Database)
" ==============================================================================
CLASS lsc_ZCIT_I_PHARMA_MAT DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
ENDCLASS.

CLASS lsc_ZCIT_I_PHARMA_MAT IMPLEMENTATION.
  METHOD save.
    " MODIFY is used instead of INSERT to prevent duplicate key short dumps
    IF lcl_buffer=>mt_drug_ins IS NOT INITIAL.   MODIFY zcit_pharma_mat FROM TABLE @lcl_buffer=>mt_drug_ins. ENDIF.
    IF lcl_buffer=>mt_drug_upd IS NOT INITIAL.   UPDATE zcit_pharma_mat FROM TABLE @lcl_buffer=>mt_drug_upd. ENDIF.
    IF lcl_buffer=>mt_drug_del IS NOT INITIAL.   DELETE zcit_pharma_mat FROM TABLE @lcl_buffer=>mt_drug_del. ENDIF.

    IF lcl_buffer=>mt_batch_ins IS NOT INITIAL.  MODIFY zcit_pharma_bat FROM TABLE @lcl_buffer=>mt_batch_ins. ENDIF.
    IF lcl_buffer=>mt_batch_upd IS NOT INITIAL.  UPDATE zcit_pharma_bat FROM TABLE @lcl_buffer=>mt_batch_upd. ENDIF.
    IF lcl_buffer=>mt_batch_del IS NOT INITIAL.  DELETE zcit_pharma_bat FROM TABLE @lcl_buffer=>mt_batch_del. ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    CLEAR: lcl_buffer=>mt_drug_ins, lcl_buffer=>mt_drug_upd, lcl_buffer=>mt_drug_del,
           lcl_buffer=>mt_batch_ins, lcl_buffer=>mt_batch_upd, lcl_buffer=>mt_batch_del.
  ENDMETHOD.
ENDCLASS.
