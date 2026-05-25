package main

import "sync"

type sessionAppairage struct {
	mu               sync.Mutex
	clePriveePC      []byte
	clePubliquePC    []byte
	pairingIdEnCours string
	tabPub           []byte
}

func (s *sessionAppairage) memoriserPairingId(pairingId string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.pairingIdEnCours = pairingId
}

func (s *sessionAppairage) lirePairingId() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.pairingIdEnCours
}

func (s *sessionAppairage) memoriserTabPub(tabPub []byte) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.tabPub = tabPub
}

func (s *sessionAppairage) lireTabPub() []byte {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.tabPub
}
