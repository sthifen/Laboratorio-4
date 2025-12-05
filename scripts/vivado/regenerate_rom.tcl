# ==============================================================================
# Script simple: Solo regenera ROM IP con firmware.coe actualizado
# Uso desde consola Tcl de Vivado:
#   source scripts/vivado/regenerate_rom.tcl
# ==============================================================================

puts "==> Buscando ROM IP..."
set rom_ip [get_ips -filter {NAME =~ "*ROM*"}]

if {[llength $rom_ip] == 0} {
    puts "ERROR: No se encontró ROM IP"
    puts "IPs disponibles: [get_ips]"
    return
}

puts "==> ROM IP encontrado: $rom_ip"
puts "==> Regenerando ROM con firmware.coe actualizado..."

reset_target all [get_ips $rom_ip]
generate_target all [get_ips $rom_ip]

puts "==> ROM regenerado exitosamente"
puts "==> Ahora puedes hacer Run Synthesis manualmente desde Vivado"
