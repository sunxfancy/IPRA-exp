#include <stdint.h>  /* for intptr */
#include <stddef.h> /* for offsetof */
#include "dr_api.h"
#include "drmgr.h"
#include "drreg.h"
#include "drx.h"
#include "droption.h"

#define SHOW_RESULTS

#ifdef WINDOWS
#    define DISPLAY_STRING(msg) dr_messagebox(msg)
#else
#    define DISPLAY_STRING(msg) dr_printf("%s\n", msg);
#endif

#define NULL_TERMINATE(buf) (buf)[(sizeof((buf)) / sizeof((buf)[0])) - 1] = '\0'

static uintptr_t global_push_count = 0;
static uintptr_t global_pop_count = 0;
static uintptr_t global_total_count = 0;

static void
event_exit(void)
{
#ifdef SHOW_RESULTS
    file_t f;
    const char* name = getenv("LLVM_IRPP_PROFILE");
    if (name == NULL) name = "regprof2.raw";
    f = dr_open_file(name, DR_FILE_WRITE_APPEND);
    dr_fprintf(f, "dynamic push count: %lu\n", global_push_count);
    dr_fprintf(f, "dynamic pop  count: %lu\n", global_pop_count);
    dr_close_file(f);
#endif /* SHOW_RESULTS */
    drx_exit();
    drreg_exit();
    drmgr_exit();
}

static dr_emit_flags_t
event_push_instruction(void *drcontext, void *tag, instrlist_t *bb, instr_t *inst,
                         bool for_trace, bool translating, void *user_data)
{
    /* Insert code to update the counter for tracking the number of executed instructions
     * having the specified opcode.
     */
    drx_insert_counter_update(
        drcontext, bb, inst,
        /* We're using drmgr, so these slots
         * here won't be used: drreg's slots will be.
         */
        static_cast<dr_spill_slot_t>(SPILL_SLOT_MAX + 1),
        IF_AARCHXX_(static_cast<dr_spill_slot_t>(SPILL_SLOT_MAX + 1)) &
            global_push_count,
        1,
        /* TODO i#4215: DRX_COUNTER_LOCK is not yet supported on ARM. */
        IF_X86_ELSE(DRX_COUNTER_LOCK, 0));

    return DR_EMIT_DEFAULT;
}


static dr_emit_flags_t
event_pop_instruction(void *drcontext, void *tag, instrlist_t *bb, instr_t *inst,
                         bool for_trace, bool translating, void *user_data)
{
    /* Insert code to update the counter for tracking the number of executed instructions
     * having the specified opcode.
     */
    drx_insert_counter_update(
        drcontext, bb, inst,
        /* We're using drmgr, so these slots
         * here won't be used: drreg's slots will be.
         */
        static_cast<dr_spill_slot_t>(SPILL_SLOT_MAX + 1),
        IF_AARCHXX_(static_cast<dr_spill_slot_t>(SPILL_SLOT_MAX + 1)) &
            global_pop_count,
        1,
        /* TODO i#4215: DRX_COUNTER_LOCK is not yet supported on ARM. */
        IF_X86_ELSE(DRX_COUNTER_LOCK, 0));

    return DR_EMIT_DEFAULT;
}


static dr_emit_flags_t
event_bb_analysis(void *drcontext, void *tag, instrlist_t *bb, bool for_trace,
                  bool translating, OUT void **user_data)
{
    intptr_t bb_size = (intptr_t)drx_instrlist_app_size(bb);
    *user_data = (void *)bb_size;
    return DR_EMIT_DEFAULT;
}

static dr_emit_flags_t
event_app_instruction(void *drcontext, void *tag, instrlist_t *bb, instr_t *inst,
                      bool for_trace, bool translating, void *user_data)
{
    /* By default drmgr enables auto-predication, which predicates all instructions with
     * the predicate of the current instruction on ARM.
     * We disable it here because we want to unconditionally execute the following
     * instrumentation.
     */
    drmgr_disable_auto_predication(drcontext, bb);
    if (!drmgr_is_first_instr(drcontext, inst))
        return DR_EMIT_DEFAULT;

    intptr_t bb_size = (intptr_t)user_data;

    drx_insert_counter_update(
        drcontext, bb, inst,
        /* We're using drmgr, so these slots
         * here won't be used: drreg's slots will be.
         */
        static_cast<dr_spill_slot_t>(SPILL_SLOT_MAX + 1),
        IF_AARCHXX_(static_cast<dr_spill_slot_t>(SPILL_SLOT_MAX + 1)) &
            global_total_count,
        (int)bb_size,
        /* TODO i#4215: DRX_COUNTER_LOCK is not yet supported on ARM. */
        IF_X86_ELSE(DRX_COUNTER_LOCK, 0));

    return DR_EMIT_DEFAULT;
}

DR_EXPORT void
dr_client_main(client_id_t id, int argc, const char *argv[])
{
    drreg_options_t ops = { sizeof(ops), 1 /*max slots needed: aflags*/, false };
    dr_set_client_name("DynamoRIO Sample Client 'opcode_count'",
                       "http://dynamorio.org/issues");
    if (!drmgr_init() || !drx_init() || drreg_init(&ops) != DRREG_SUCCESS)
        DR_ASSERT(false);

    /* Register opcode event. */
    dr_register_exit_event(event_exit);
    if (!drmgr_register_opcode_instrumentation_event(event_push_instruction,
                                                     OP_push, NULL, NULL) 
        || !drmgr_register_opcode_instrumentation_event(event_pop_instruction,
                                                     OP_pop, NULL, NULL) 
        // || !drmgr_register_bb_instrumentation_event(event_bb_analysis, event_app_instruction,
        //                                          NULL)
        )
        DR_ASSERT(false);

    /* Make it easy to tell, by looking at log file, which client executed. */
    dr_log(NULL, DR_LOG_ALL, 1, "Client 'opcode_count' initializing\n");
#ifdef SHOW_RESULTS
    /* also give notification to stderr */
    if (dr_is_notify_on()) {
#    ifdef WINDOWS
        /* Ask for best-effort printing to cmd window. This must be called at init. */
        dr_enable_console_printing();
#    endif
        dr_fprintf(STDERR, "Client opcode_count is running and considering opcode: push and pop.\n");
    }
#endif
}