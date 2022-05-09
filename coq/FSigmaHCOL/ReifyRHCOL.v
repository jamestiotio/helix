(* Translates RHCOL to FHCOL *)

Require Import Helix.MSigmaHCOL.RasCT.
Require Import Helix.RSigmaHCOL.NatAsNT.
Require Import Helix.FSigmaHCOL.Float64asCT.
Require Import Helix.FSigmaHCOL.Int64asNT.
Require Import Helix.RSigmaHCOL.RSigmaHCOL.
Require Import Helix.FSigmaHCOL.FSigmaHCOL.
Require Import Helix.DSigmaHCOL.DHCOLTypeTranslator.

Module Export RHCOLtoFHCOL := MDHCOLTypeTranslator
                                 (MRasCT)
                                 (MFloat64asCT)
                                 (MNatAsNT)
                                 (MInt64asNT)
                                 (RHCOL)
                                 (FHCOL)
                                 (RHCOLEval)
                                 (FHCOLEval).
