package app.time2wish.service;

import app.time2wish.dto.FundraiserDto;
import app.time2wish.dto.PledgeRequest;
import app.time2wish.model.Fundraiser;
import app.time2wish.model.Gift;
import app.time2wish.model.Pledge;
import app.time2wish.model.User;
import app.time2wish.repository.FundraiserRepository;
import app.time2wish.repository.GiftRepository;
import app.time2wish.repository.PledgeRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("FundraiserService – Tests Unitaires")
class FundraiserServiceTest {

    @Mock
    private FundraiserRepository fundraiserRepository;

    @Mock
    private PledgeRepository pledgeRepository;

    @Mock
    private GiftRepository giftRepository;

    @InjectMocks
    private FundraiserService fundraiserService;

    private Gift gift;
    private Fundraiser fundraiser;
    private User user;

    @BeforeEach
    void setUp() {
        user = new User();
        user.setId(1L);
        user.setFullName("Jean Dupont");

        gift = Gift.builder()
                .id(100L)
                .name("Casque Audio")
                .priceRange("50€ - 80€")
                .build();

        fundraiser = Fundraiser.builder()
                .id(1L)
                .gift(gift)
                .targetAmount(new BigDecimal("80.0"))
                .currency("EUR")
                .active(true)
                .build();
    }

    @Test
    @DisplayName("Création d'une cagnotte en extrayant le prix du cadeau")
    void testGetOrCreateFundraiser_ParsesGiftPrice() {
        when(fundraiserRepository.findByGiftId(100L)).thenReturn(Optional.empty());
        when(giftRepository.findById(100L)).thenReturn(Optional.of(gift));
        when(fundraiserRepository.save(any(Fundraiser.class))).thenAnswer(inv -> inv.getArgument(0));
        when(pledgeRepository.findByFundraiserIdOrderByCreatedAtDesc(any())).thenReturn(Collections.emptyList());

        FundraiserDto dto = fundraiserService.getOrCreateFundraiser(100L, null);

        assertThat(dto).isNotNull();
        assertThat(dto.getTargetAmount()).isEqualByComparingTo("80.0");
        assertThat(dto.getCurrentAmount()).isEqualByComparingTo("0.0");
        assertThat(dto.getRemainingAmount()).isEqualByComparingTo("80.0");
        assertThat(dto.getIsCompleted()).isFalse();
    }

    @Test
    @DisplayName("Ajout d'une promesse valide dans la limite du montant restant")
    void testAddPledge_SuccessWithinLimit() {
        when(fundraiserRepository.findById(1L)).thenReturn(Optional.of(fundraiser));
        when(pledgeRepository.findByFundraiserIdOrderByCreatedAtDesc(1L)).thenReturn(Collections.emptyList());

        PledgeRequest request = new PledgeRequest();
        request.setAmount(new BigDecimal("30.0"));
        request.setGuestName("Alice");

        fundraiserService.addPledge(1L, user, request);

        verify(pledgeRepository, times(1)).save(any(Pledge.class));
    }

    @Test
    @DisplayName("Rejet d'une promesse qui dépasse la somme restante à collecter")
    void testAddPledge_ExceedsLimit() {
        Pledge existingPledge = Pledge.builder()
                .id(10L)
                .amount(new BigDecimal("60.0"))
                .build();

        when(fundraiserRepository.findById(1L)).thenReturn(Optional.of(fundraiser));
        when(pledgeRepository.findByFundraiserIdOrderByCreatedAtDesc(1L)).thenReturn(List.of(existingPledge));

        PledgeRequest request = new PledgeRequest();
        request.setAmount(new BigDecimal("25.0")); // remaining is 20, 25 exceeds it!

        assertThatThrownBy(() -> fundraiserService.addPledge(1L, user, request))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("ne peut pas dépasser la somme restante");

        verify(pledgeRepository, never()).save(any(Pledge.class));
    }

    @Test
    @DisplayName("Clôture automatique de la cagnotte lorsque l'objectif est atteint à 100%")
    void testAddPledge_ReachesExactGoal() {
        Pledge existingPledge = Pledge.builder()
                .id(10L)
                .amount(new BigDecimal("50.0"))
                .build();

        when(fundraiserRepository.findById(1L)).thenReturn(Optional.of(fundraiser));
        when(pledgeRepository.findByFundraiserIdOrderByCreatedAtDesc(1L)).thenReturn(List.of(existingPledge));

        PledgeRequest request = new PledgeRequest();
        request.setAmount(new BigDecimal("30.0")); // exact remaining: 50 + 30 = 80

        fundraiserService.addPledge(1L, user, request);

        verify(pledgeRepository, times(1)).save(any(Pledge.class));
        assertThat(fundraiser.getActive()).isFalse();
        verify(fundraiserRepository, times(1)).save(fundraiser);
    }

    @Test
    @DisplayName("Rejet d'une promesse si la cagnotte est déjà clôturée")
    void testAddPledge_ClosedFundraiser() {
        fundraiser.setActive(false);
        when(fundraiserRepository.findById(1L)).thenReturn(Optional.of(fundraiser));

        PledgeRequest request = new PledgeRequest();
        request.setAmount(new BigDecimal("10.0"));

        assertThatThrownBy(() -> fundraiserService.addPledge(1L, user, request))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("clôturée");
    }

    @Test
    @DisplayName("Modification du montant cible impossible si inférieur aux dons existants")
    void testUpdateTargetAmount_CannotBeLowerThanCurrent() {
        Pledge existingPledge = Pledge.builder()
                .id(10L)
                .amount(new BigDecimal("40.0"))
                .build();

        when(fundraiserRepository.findById(1L)).thenReturn(Optional.of(fundraiser));
        when(pledgeRepository.findByFundraiserIdOrderByCreatedAtDesc(1L)).thenReturn(List.of(existingPledge));

        assertThatThrownBy(() -> fundraiserService.updateTargetAmount(1L, new BigDecimal("30.0")))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("ne peut pas être inférieur");
    }
}
