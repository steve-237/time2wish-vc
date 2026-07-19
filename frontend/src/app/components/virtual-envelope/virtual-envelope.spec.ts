import { ComponentFixture, TestBed } from '@angular/core/testing';

import { VirtualEnvelope } from './virtual-envelope';

describe('VirtualEnvelope', () => {
  let component: VirtualEnvelope;
  let fixture: ComponentFixture<VirtualEnvelope>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [VirtualEnvelope],
    }).compileComponents();

    fixture = TestBed.createComponent(VirtualEnvelope);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
