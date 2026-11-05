using System.ComponentModel.DataAnnotations;

namespace RestauranteApi.Models;

public partial class Reserva : IValidatableObject
{
    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (FechaHora.Kind != DateTimeKind.Unspecified)
            yield return new ValidationResult(
                "FechaHora debe usar hora local de Lima, sin Z ni offset.", [nameof(FechaHora)]);
    }
}
