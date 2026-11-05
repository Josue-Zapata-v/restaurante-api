using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RestauranteApi.Data;
using RestauranteApi.Models;

namespace RestauranteApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class MesasController(RestauranteContext context) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<List<Mesa>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<List<Mesa>>> GetMesas(CancellationToken ct)
    {
        return Ok(await context.Mesas.AsNoTracking().OrderBy(m => m.Numero).ToListAsync(ct));
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType<Mesa>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<Mesa>> GetMesa(int id, CancellationToken ct)
    {
        var mesa = await context.Mesas.AsNoTracking().FirstOrDefaultAsync(m => m.Id == id, ct);
        return mesa is null ? NotFound() : Ok(mesa);
    }

    [HttpGet("{id:int}/reservas")]
    [ProducesResponseType<List<Reserva>>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<List<Reserva>>> GetReservasDeMesa(int id, CancellationToken ct)
    {
        if (!await context.Mesas.AnyAsync(m => m.Id == id, ct)) return NotFound();
        return Ok(await context.Reservas.AsNoTracking().Where(r => r.MesaId == id)
            .OrderBy(r => r.FechaHora).ToListAsync(ct));
    }

    [HttpPost]
    [ProducesResponseType<Mesa>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<Mesa>> PostMesa(Mesa entrada, CancellationToken ct)
    {
        if (entrada.Id != 0) return BadRequest(new { mensaje = "El Id se genera automáticamente; envía 0 u omítelo." });
        if (await context.Mesas.AnyAsync(m => m.Numero == entrada.Numero, ct))
            return Conflict(new { mensaje = "Ya existe una mesa con ese número." });

        var mesa = new Mesa
        {
            Numero = entrada.Numero, Capacidad = entrada.Capacidad, Ubicacion = entrada.Ubicacion.Trim()
        };
        context.Mesas.Add(mesa);
        await context.SaveChangesAsync(ct);
        return CreatedAtAction(nameof(GetMesa), new { id = mesa.Id }, mesa);
    }

    [HttpPut("{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> PutMesa(int id, Mesa entrada, CancellationToken ct)
    {
        if (id != entrada.Id) return BadRequest(new { mensaje = "El Id de la ruta debe coincidir con el del cuerpo." });

        // Conserva la regla de capacidad incluso si se registra una reserva concurrente.
        await using var transaction = await context.Database.BeginTransactionAsync(IsolationLevel.Serializable, ct);
        var mesa = await context.Mesas.FindAsync([id], ct);
        if (mesa is null) return NotFound();
        if (await context.Mesas.AnyAsync(m => m.Numero == entrada.Numero && m.Id != id, ct))
            return Conflict(new { mensaje = "Ya existe una mesa con ese número." });
        if (await context.Reservas.AnyAsync(r => r.MesaId == id && r.CantidadPersonas > entrada.Capacidad, ct))
            return Conflict(new { mensaje = "La capacidad no puede ser menor que la cantidad de personas de una reserva asociada." });

        mesa.Numero = entrada.Numero;
        mesa.Capacidad = entrada.Capacidad;
        mesa.Ubicacion = entrada.Ubicacion.Trim();
        await context.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> DeleteMesa(int id, CancellationToken ct)
    {
        var mesa = await context.Mesas.FindAsync([id], ct);
        if (mesa is null) return NotFound();
        if (await context.Reservas.AnyAsync(r => r.MesaId == id, ct))
            return Conflict(new { mensaje = "No se puede eliminar una mesa con reservas asociadas." });

        context.Mesas.Remove(mesa);
        await context.SaveChangesAsync(ct);
        return NoContent();
    }
}
