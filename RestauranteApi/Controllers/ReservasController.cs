using System.ComponentModel.DataAnnotations;
using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RestauranteApi.Data;
using RestauranteApi.Models;

namespace RestauranteApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class ReservasController(RestauranteContext context) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<List<Reserva>>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<List<Reserva>>> GetReservas(
        [FromQuery, Range(1, int.MaxValue)] int? mesaId,
        [FromQuery] DateTime? desde, [FromQuery] DateTime? hasta, CancellationToken ct)
    {
        if ((desde.HasValue && desde.Value.Kind != DateTimeKind.Unspecified)
            || (hasta.HasValue && hasta.Value.Kind != DateTimeKind.Unspecified))
            return BadRequest(new { mensaje = "Usa fechas en hora local de Lima, sin Z ni offset." });
        if (desde.HasValue && hasta.HasValue && desde > hasta)
            return BadRequest(new { mensaje = "Desde no puede ser posterior a hasta." });

        var query = context.Reservas.AsNoTracking().Include(r => r.Mesa).AsQueryable();
        if (mesaId.HasValue) query = query.Where(r => r.MesaId == mesaId.Value);
        if (desde.HasValue) query = query.Where(r => r.FechaHora >= desde.Value);
        if (hasta.HasValue) query = query.Where(r => r.FechaHora <= hasta.Value);
        return Ok(await query.OrderBy(r => r.FechaHora).ThenBy(r => r.Id).ToListAsync(ct));
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType<Reserva>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<Reserva>> GetReserva(int id, CancellationToken ct)
    {
        var reserva = await context.Reservas.AsNoTracking().Include(r => r.Mesa)
            .FirstOrDefaultAsync(r => r.Id == id, ct);
        return reserva is null ? NotFound() : Ok(reserva);
    }

    [HttpPost]
    [ProducesResponseType<Reserva>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<Reserva>> PostReserva(Reserva entrada, CancellationToken ct)
    {
        if (entrada.Id != 0) return BadRequest(new { mensaje = "El Id se genera automáticamente; envía 0 u omítelo." });
        await using var transaction = await context.Database.BeginTransactionAsync(IsolationLevel.Serializable, ct);
        var mesa = await context.Mesas.FindAsync([entrada.MesaId], ct);
        if (mesa is null) return BadRequest(new { mensaje = "La mesa indicada no existe." });
        if (entrada.CantidadPersonas > mesa.Capacidad)
            return Conflict(new { mensaje = "La cantidad de personas supera la capacidad de la mesa." });

        // Solo se copian escalares: nunca se inserta una mesa recibida dentro del JSON.
        var reserva = new Reserva
        {
            NombreCliente = entrada.NombreCliente.Trim(), Telefono = entrada.Telefono.Trim(),
            FechaHora = entrada.FechaHora, CantidadPersonas = entrada.CantidadPersonas,
            Observaciones = entrada.Observaciones?.Trim(), MesaId = entrada.MesaId
        };
        context.Reservas.Add(reserva);
        await context.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
        return CreatedAtAction(nameof(GetReserva), new { id = reserva.Id }, reserva);
    }

    [HttpPut("{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> PutReserva(int id, Reserva entrada, CancellationToken ct)
    {
        if (id != entrada.Id) return BadRequest(new { mensaje = "El Id de la ruta debe coincidir con el del cuerpo." });
        await using var transaction = await context.Database.BeginTransactionAsync(IsolationLevel.Serializable, ct);
        var reserva = await context.Reservas.FindAsync([id], ct);
        if (reserva is null) return NotFound();
        var mesa = await context.Mesas.FindAsync([entrada.MesaId], ct);
        if (mesa is null) return BadRequest(new { mensaje = "La mesa indicada no existe." });
        if (entrada.CantidadPersonas > mesa.Capacidad)
            return Conflict(new { mensaje = "La cantidad de personas supera la capacidad de la mesa." });

        reserva.NombreCliente = entrada.NombreCliente.Trim();
        reserva.Telefono = entrada.Telefono.Trim();
        reserva.FechaHora = entrada.FechaHora;
        reserva.CantidadPersonas = entrada.CantidadPersonas;
        reserva.Observaciones = entrada.Observaciones?.Trim();
        reserva.MesaId = entrada.MesaId;
        await context.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteReserva(int id, CancellationToken ct)
    {
        var reserva = await context.Reservas.FindAsync([id], ct);
        if (reserva is null) return NotFound();
        context.Reservas.Remove(reserva);
        await context.SaveChangesAsync(ct);
        return NoContent();
    }
}
